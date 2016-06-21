module AdminHelper
  def heroku_client(username = nil, password = nil)
    if session[:heroku]
      username ||= session[:heroku][:username]
      password ||= session[:heroku][:password]
    end
    
    @heroku_client ||= Excon.new('https://api.heroku.com', user: username, password: password)
  end
  
  def subdomain
    settings.development? ? 'glacial-temple-66068' : request.host.split('.').first
  end
  
  def store_config
    heroku_client.patch({
      method: 'PATCH',
      path: "/apps/#{subdomain}/config-vars",
      body: JSON.fast_generate(validator.to_config),
      headers: { "Accept" => "application/vnd.heroku+json; version=3" }
    }).status == 200
  end
  
  def validator
    @validator ||= FormValidator.new(params)
  end
  
  class FormValidator
    include ActiveModel::Model
    
    attr_accessor :desk_domain, :shared_key, :adapter, :dropbox_adapter
    
    validates_presence_of :desk_domain, :shared_key
    validate :instance_validations
    
    def instance_validations
      validates_with DropboxAdapter::Validator if adapter == 'dropbox_adapter'
    end
    
    def to_config
      {
        'DESK_DOMAIN' => desk_domain,
        'ADAPTER' => adapter,
        'SHARED_KEY' => shared_key
      }.merge(send("#{adapter}_params"))
    end
    
    def adapter_params
      if adapter == 'dropbox_adapter'
        dropbox_params
      end
    end
    
    def dropbox_adapter_params
      DropboxAdapter::MAPPING.inject({}) { |hash, (k, v)| hash.merge(v => dropbox_adapter[k]) }
    end
  end
end