class AdminController < ApplicationController
  helpers AdminHelper
  
  before /^\/(?!login)/ do
    if !session.key?(:heroku)
      redirect '/admin/login'
    end
  end
  
  get '/' do
    title 'Admin'
    style 'css/admin.css'
    erb :admin
  end
  
  post '/' do
    redirect '/?success=true' if validator.valid? && store_config
    title 'Admin'
    style 'css/admin.css'
    erb :admin
  end
  
  get '/login' do
    title 'Login'
    style 'css/login.css'
    erb :login
  end
  
  post '/login' do
    account = JSON.parse(heroku_client(params[:username], params[:password]).get(path: '/account').body)
    if account['email'] == params[:username]
      # app = JSON.parse(heroku_client.get(path: "/apps/#{subdomain}").body)
      # if app['owner_email'] == params[:username]
        session[:heroku] = { username: params[:username], password: params[:password] }
        redirect '/admin'
      # end
    end
    redirect '/admin/login'
  end
end