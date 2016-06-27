require_relative 'base_adapter'
require 'dropbox_sdk'

class DropboxAdapter < BaseAdapter
  BaseAdapter::ADAPTERS.merge!({ dropbox_adapter: 'Dropbox' })
  MAPPING = {
    access_token: 'DROPBOX_ACCESS_TOKEN'
  }
  REFACTOR = lambda do |item|
    {
      id: File.basename(item['path']),
      name: File.basename(item['path']),
      modified: item['modified'],
      size: item['bytes'],
      type: item['is_dir'] ? 'folder' : 'file'
    }
  end
  
  class Validator < ActiveModel::Validator
    def validate(record)
      ad = DropboxAdapter.new(record.send(:dropbox_adapter).with_indifferent_access)
      ad.client.account_info.is_a?(Hash)
    rescue DropboxError
      record.errors.add(:dropbox_adapter, 'invalid credentials')
    end
  end

  def client
    @client ||= DropboxClient.new(@options[:access_token] || ENV[MAPPING[:access_token]])
  end
  
  def create_folder(id)
    super("/#{id.to_s}", REFACTOR.call(client.file_create_folder("/#{id.to_s}")))
  end
  
  def delete_folder(id)
    return super("/#{id.to_s}") if client.file_delete("/#{id.to_s}")['is_deleted']
    false
  end
  
  def folders(id = nil)
    super("/#{id.to_s}")
  end
  
  def create_file(folder_id, file)
    path = "/#{folder_id.to_s}/#{file[:filename]}"
    file = client.put_file(path, file[:tempfile])
    super file['path'], REFACTOR.call(file)
  end
  
  def delete_file(folder_id, file_id)
    path = "/#{folder_id.to_s}/#{file_id.to_s}"
    return super(path) if client.file_delete(path)['is_deleted']
    false
  end
  
  def download_file(folder_id, file_id)
    path = "/#{folder_id.to_s}/#{file_id.to_s}"
    [store.find(path), client.get_file(path)]
  end
  
  def files(folder_id, file_id = nil)
    path = "/#{folder_id.to_s}" + (file_id.nil? ? '' : "/#{file_id.to_s}")
    super path
  end
end