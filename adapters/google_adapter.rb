require_relative 'base_adapter'
require 'googleauth'
require 'google/apis/drive_v3'

class GoogleAdapter < BaseAdapter
  BaseAdapter::ADAPTERS.merge!({ google_adapter: 'Google Drive' })
  SCOPE   = [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata'
  ]
  MAPPING = {
    private_key: 'GOOGLE_PRIVATE_KEY',
    client_email: 'GOOGLE_CLIENT_EMAIL',
    client_id: 'GOOGLE_CLIENT_ID',
    account_type: 'GOOGLE_ACCOUNT_TYPE'
  }
  REFACTOR = lambda do |item|
    {
      id: item.id,
      name: item.name,
      modified: item.modified_time,
      size: item.size,
      type: item.mime_type == 'application/vnd.google-apps.folder' ? 'folder' : 'file'
    }
  end
  FIELDS = 'id,kind,modifiedTime,name,size,mimeType'
  
  class Validator < ActiveModel::Validator
    def validate(record)
      ad = GoogleAdapter.new(record.send(:google_adapter))
      ad.client.list_files.is_a?(Google::Apis::DriveV3::FileList)
    rescue DropboxError
      record.errors.add(:google_adapter, 'invalid credentials')
    end
  end
  
  def client
    @client ||= begin
      client = Google::Apis::DriveV3::DriveService.new
      client.client_options.application_name = 'Desk.com Drive'
      client.authorization = auth
      client
    end
  end
  
  def auth
    @auth ||= begin
      key = @options[:private_key].gsub(/[\s]+/, "\n")
      puts key
      $logger.info key
    
      Google::Auth::ServiceAccountCredentials.new(
        token_credential_uri: Google::Auth::ServiceAccountCredentials::TOKEN_CRED_URI,
        audience: Google::Auth::ServiceAccountCredentials::TOKEN_CRED_URI,
        scope: SCOPE,
        issuer: @options[:client_email],
        signing_key: OpenSSL::PKey::RSA.new(key))
      )
    end
  end
  
  def find_or_create_folder(id)
    store.find("/#{id}").id || begin
      create_folder(id)
      store.find("/#{id}").id
    end
  end
  
  def create_folder(id)
    folder = REFACTOR.call(client.create_file({
      name: id.to_s,
      parents: ['appDataFolder'],
      mime_type: 'application/vnd.google-apps.folder'
    }, fields: FIELDS))

    super("/#{id.to_s}", folder)
  end
  
  def delete_folder(id)
    client.delete_file(store.find("/#{id.to_s}").id)
    super("/#{id.to_s}")
  rescue Google::Apis::Error
    false
  end
  
  def folders(id)
    super("/#{id.to_s}")
  end
  
  def create_file(folder_id, file)
    meta = { name: file[:filename], parents: [
      find_or_create_folder(folder_id)
    ] }
    file = REFACTOR.call client.create_file(meta, {
      upload_source: file[:tempfile],
      fields: FIELDS
    })
    super("/#{folder_id.to_s}/#{file[:id].to_s}", file)
  end
  
  def delete_file(folder_id, file_id)
    path = "/#{folder_id.to_s}/#{file_id.to_s}"
    client.delete_file(store.find(path).id)
    super(path)
  rescue Google::Apis::Error
    false
  end
  
  def download_file(folder_id, file_id)
    file = store.find("/#{folder_id.to_s}/#{file_id.to_s}")
    dest = Tempfile.new
    client.get_file(file.id, download_dest: dest)
    dest.rewind
    [file, dest.read]
  end
  
  def files(folder_id, file_id = nil)
    path = "/#{folder_id.to_s}" + (file_id.nil? ? '' : "/#{file_id.to_s}")
    super path
  end
end