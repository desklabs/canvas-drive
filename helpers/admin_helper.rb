require 'platform-api'
require 'active_model'

module AdminHelper
  def heroku
    if session[:heroku]
      username ||= session[:heroku][:username]
      password ||= session[:heroku][:password]
    end
    
    @heroku ||= PlatformAPI.connect(password, user: username)
  end
  
  def authenticated?
    if session[:heroku]
      heroku.collaborator.info(subdomain, session[:heroku][:username]).is_a?(Hash)
    else
      false
    end
  rescue Excon::Errors::NotFound
    false
  end
  
  def subdomain
    settings.development? ? 'canvas-drive' : request.host.split('.').first
  end
  
  def store_config
    heroku.config_var.update(subdomain, validator.to_config).is_a? Hash
  end
  
  def get_config
    heroku.config_var.info(subdomain)
  end
  
  def validator
    @validator ||= FormValidator.new(params) if request.form_data?
    @validator ||= FormValidator.from_config(get_config)
  end
  
  class FormValidator
    include ActiveModel::Model
    
    MAPPING = {
      desk_domain: 'DESK_DOMAIN',
      adapter: 'ADAPTER',
      shared_key: 'SHARED_KEY',
      session_secret: 'SESSION_SECRET'
    }
    
    attr_accessor :desk_domain, :shared_key, :adapter, :session_secret
    
    validates_presence_of :desk_domain, :shared_key, :session_secret
    validate :instance_validations

    def instance_validations
      validates_with "#{adapter.classify}::Validator".constantize
    end
    
    def self.from_config(config)
      self.new.tap do |i|
        config.each_pair do |key, value|
          if i.respond_to?(:"#{MAPPING.key(key)}=")
            i.send(:"#{MAPPING.key(key)}=", value)
          end
        end
        
        if adapter
          adapter_config = i.adapter_config.inject({}) do |hash, (k, v)|
            hash.merge(k => config[v]) if config.key?(v)
          end 
          
          i.send(:"#{i.adapter}=", adapter_config)
        end
      end
    end
    
    def adapter=(value)
      old_value = @adapter
      
      if old_value && old_value != value && respond_to?(:"#{old_value}=")
        self.class.class_eval { undef :"#{old_value}"; undef :"#{old_value}=" }
      end
      self.class.class_eval { attr_accessor value }
      
      @adapter = value
    end
    
    def adapter_config
      "#{adapter.to_s.classify}::MAPPING".constantize
    end
    
    def to_config
      adapter_config.inject({}) do |hash, (k, v)|
        hash.merge(v => send(:"#{adapter}")[k])
      end.merge({
        'DESK_DOMAIN' => desk_domain,
        'ADAPTER' => adapter,
        'SHARED_KEY' => shared_key,
        'SESSION_SECRET' => session_secret
      })
    end
  end
end