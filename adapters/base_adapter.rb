require 'active_model'
require 'active_support/core_ext/hash'
require 'active_support/inflector'
require 'securerandom'
require 'json'
require 'redis'

class BaseAdapter
  ADAPTERS    = {}
  MAPPING     = {}
  FORM_FIELDS = {}
  
  class Item < Struct.new(:id, :name, :modified, :size, :type)
    def self.from_h(hash)
      new.tap do |x|
        hash.each_pair do |key, value|
          x.send(:"#{key.to_s}=", value) if x.respond_to?(:"#{key.to_s}=")
        end
      end
    end
    
    def self.from_json(json)
      from_h(JSON.parse(json || '{}'))
    end
    
    def to_json(*a)
      to_h.to_json(*a)
    end
    
    def to_h
      { id: id, name: name, modified: modified, size: size, type: type }
    end
  end
  
  class Store < Redis
    def folders(path)
      by_path(path).select { |i| i.type == 'folder' }
    end
    
    def files(path)
      by_path(path).select { |i| i.type == 'file' }
    end
    
    def find(path)
      Item.from_json(get(path))
    end
    
    def create(path, item)
      set(path, item.to_json)
    end
    
    def delete(path)
      del(path) == 1
    end
    
    def by_path(path)
      scan_each(match: "#{path}*").map{ |p| find(p) }
    end
    
    def token(path)
      SecureRandom.uuid.tap do |tok|
        set(tok, path)
        expire(tok, 86400)
      end
    end
  end
  
  def initialize(args = {})
    mapping  = "#{self.class.name}::MAPPING".constantize
    @options = mapping.keys.each_with_object({}) do |k, h|
      h[k] = ENV[mapping[k]]
    end.merge(args.symbolize_keys)
  end
  
  def create_folder(path, folder)
    store.create(path, folder)
  end
  
  def delete_folder(path)
    store.delete(path)
  end
  
  def folders(path)
    store.folders(path)
  end
  
  def create_file(path, file)
    store.create(path, file)
  end
  
  def delete_file(path)
    store.delete(path)
  end
  
  def files(path)
    store.files(path)
  end
  
  def token(path)
    { token: store.token(path), path: path }
  end
  
  def validate_token(token, path)
    store.get(token) == path
  end
  
  def download_file(filder_id, file_id)
    [Item.new, '']
  end
  
  def store
    $store ||= Store.new url: ENV["REDIS_URL"]
  end
end