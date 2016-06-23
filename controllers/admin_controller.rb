require_relative 'application_controller'

class AdminController < ApplicationController
  helpers AdminHelper
  
  before /^\/(?!login)/ do
    if !authenticated?
      redirect '/admin/login'
    end
  end
  
  before do
    validator if authenticated?
  end
  
  get '/' do
    title 'Admin'
    style 'css/admin.css'
    erb :admin, locals: { adapters: BaseAdapter::ADAPTERS, success: params[:success] }
  end
  
  post '/' do
    redirect '/admin/?success=true' if validator.valid? && store_config
    title 'Admin'
    style 'css/admin.css'
    erb :admin, locals: { adapters: BaseAdapter::ADAPTERS, success: params[:success] }
  end
  
  get '/login' do
    title 'Login'
    style 'css/login.css'
    erb :login
  end
  
  post '/login' do
    session[:heroku] = { username: params[:username], password: params[:password] }
    redirect '/admin' if authenticated?
    redirect '/admin/logout'
  end
  
  get '/logout' do
    session.clear
    redirect '/admin/login'
  end
end