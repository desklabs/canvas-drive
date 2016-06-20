require_relative 'base_adapter'
require 'dropbox_sdk'

class DropboxAdapter < BaseAdapter
  def initialize
    @client = DropboxClient.new(ENV['DROPBOX_ACCESS_TOKEN'])
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

end