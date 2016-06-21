class ApplicationController < Sinatra::Base
  helpers ApplicationHelper
  set :views, File.expand_path('../../views', __FILE__)
  
  configure :production, :development do
    enable :sessions, :logging
    
    set :force_ssl, true
    set :port, ENV['PORT'] || 3000
    set :bind, ENV['IP'] || '0.0.0.0'
    set :session_secret, ENV['SESSION_SECRET']
    set :public_folder, File.expand_path('../../public', __FILE__)
  end
  
  configure :development do
    enable :dump_errors, :raise_errors, :show_exceptions
  end
  
  before do
    if settings.force_ssl && !request.secure?
      halt 400, "<h1>Please use SSL at https://#{request.host}</h1>"
    end
  end
  
  not_found do
    title 'Not Found!'
    erb :not_found
  end
end