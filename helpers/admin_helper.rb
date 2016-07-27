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
    settings.development? ? ENV['HEROKU_SUBDOMAIN'] : request.host.split('.').first
  end
  
  def store_config
    heroku.config_var.update(subdomain, validator.to_config).is_a? Hash
  end
  
  def get_config
    heroku.config_var.info(subdomain)
  end
  
  def validator
    @validator ||= FormValidator.from_params(params) if request.form_data?
    @validator ||= FormValidator.from_config(get_config)
  end
  
  class FormValidator
    include ActiveModel::Model
    
    MAPPING = {
      adapter: 'ADAPTER',
      shared_key: 'SHARED_KEY',
      session_secret: 'SESSION_SECRET',
      desk_endpoint: 'DESK_ENDPOINT',
      desk_consumer_key: 'DESK_CONSUMER_KEY',
      desk_consumer_secret: 'DESK_CONSUMER_SECRET',
      desk_token: 'DESK_TOKEN',
      desk_token_secret: 'DESK_TOKEN_SECRET',
      resque_user: 'RESQUE_USER',
      resque_password: 'RESQUE_PASSWORD'
    }
    
    attr_accessor :desk_endpoint, :desk_consumer_key, :desk_consumer_secret,
                  :desk_token, :desk_token_secret, :shared_key, :adapter,
                  :session_secret, :resque_user, :resque_password
    
    validates_presence_of :desk_endpoint, :desk_consumer_key,
                          :desk_consumer_secret, :desk_token, :shared_key,
                          :session_secret
    
    validate :instance_validations

    def instance_validations
      validates_with "#{adapter.classify}::Validator".constantize
      validates_with DeskValidator
    end
    
    def self.from_params(params)
      self.new.tap do |i|
        i.from_hash(params)
      end
    end
    
    def self.from_config(config)
      self.new.tap do |i|
        i.from_hash(i.clean_config(config))
        
        if i.adapter
          adapter_config = i.adapter_config.inject({}) do |hash, (k, v)|
            hash.merge(k => config[v]) if config.key?(v)
          end 
          
          i.send(:"#{i.adapter}=", adapter_config)
        end
      end
    end
    
    def clean_config(config = {})
      config.each_with_object({}) do |(k, v), hsh|
        hsh[MAPPING.key(k)] = v if MAPPING.value?(k)
      end
    end
    
    def from_hash(hash = {})
      hash.each_pair do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
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
        'ADAPTER' => adapter,
        'SHARED_KEY' => shared_key,
        'SESSION_SECRET' => session_secret,
        'DESK_ENDPOINT' => desk_endpoint,
        'DESK_CONSUMER_KEY' => desk_consumer_key,
        'DESK_CONSUMER_SECRET' => desk_consumer_secret,
        'DESK_TOKEN' => desk_token,
        'DESK_TOKEN_SECRET' => desk_token_secret,
        'RESQUE_USER' => resque_user,
        'RESQUE_PASSWORD' => resque_password
      })
    end
    
    class DeskValidator < ActiveModel::Validator
      def validate(record)
        client = DeskApi::Client.new({
          endpoint: record.desk_endpoint,
          consumer_key: record.desk_consumer_key,
          consumer_secret: record.desk_consumer_secret,
          token: record.desk_token,
          token_secret: record.desk_token_secret
        })
        client.by_url('/api/v2/users/me').name
      rescue StandardError
        record.errors.add(:desk_endpoint, 'invalid credentials')
        record.errors.add(:desk_consumer_key, 'invalid credentials')
        record.errors.add(:desk_consumer_secret, 'invalid credentials')
        record.errors.add(:desk_token, 'invalid credentials')
        record.errors.add(:desk_token_secret, 'invalid credentials')
      end
    end
  end
end