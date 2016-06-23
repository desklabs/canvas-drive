require_relative 'base_adapter'
require 'dropbox_sdk'

class DropboxAdapter < BaseAdapter
  BaseAdapter::ADAPTERS.merge!({ dropbox_adapter: 'Dropbox' })
  MAPPING = {
    access_token: 'DROPBOX_ACCESS_TOKEN'
  }
  
  def initialize(args = {})
    @client = DropboxClient.new(args[:access_token] || ENV[MAPPING[:access_token]])
    @refactor = lambda do |item|
      {
        path: item['path'],
        name: File.basename(item['path']),
        modified: item['modified'],
        size: item['bytes']
      }
    end
  end
  
  def create_folder(id)
    @refactor.call(@client.file_create_folder("/#{id.to_s}"))
  end
  
  def delete_folder(id)
    @client.file_delete("/#{id.to_s}")['is_deleted']
  end
  
  def folders(id = nil)
    meta = @client.metadata("/#{id.to_s}")
    if id.nil?
      meta['contents'].select { |c| c['is_dir'] }.map(&@refactor)
    else
      @refactor.call(meta)
    end
  end
  
  def create_file(folder_id, file)
    @refactor.call(@client.put_file("/#{folder_id.to_s}/#{file[:filename]}", file[:tempfile]))
  end
  
  def delete_file(folder_id, file_id)
    delete_folder("#{folder_id.to_s}/#{file_id.to_s}")
  end
  
  def download_file(folder_id, file_id)
    @client.get_file("/#{folder_id.to_s}/#{file_id.to_s}")
  end
  
  def files(folder_id, file_id = nil)
    path = folder_id.to_s + (file_id.nil? ? '' : "/#{file_id.to_s}")
    meta = @client.metadata("/#{path}")
    
    if file_id.nil?
      meta['contents'].select { |c| !c['is_dir'] }.map(&@refactor)
    else
      @refactor.call(meta)
    end
  end


  class Validator < ActiveModel::Validator
    def validate(record)
      ad = DropboxAdapter.new(record.send(:dropbox_adapter))
      ad.instance_variable_get(:@client).account_info.is_a?(Hash)
    rescue DropboxError
      record.errors.add(:dropbox_adapter, 'invalid credentials')
    end
  end
end