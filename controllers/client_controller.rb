require_relative 'application_controller'
require 'active_support'

class ClientController < ApplicationController
  helpers ClientHelper
  
  configure :production, :development do
    set :protection, frame_options: "ALLOW-FROM #{ENV['DESK_DOMAIN']}"
    set :adapter, ENV['ADAPTER'].classify.constantize.new if ENV['ADAPTER']
  end
  
  before do
    if request.post? && params[:signed_request]
      session[:signed_request] = parse_signed_request(params[:signed_request])
    end
  end

  before /^(?!\/(login|download))/ do
    halt 401, '<h1>Unauthorized</h1>' unless logged_in?
  end
  
  get '/' do
    title "File Explorer"
    style "css/fileinput.min.css"
    erb :index
  end
  
  post '/login' do
    redirect '/'
  end
  
  # fetches all the folders
  get '/folders' do
    content_type :json
    status 200
    settings.adapter.folders.to_json
  end
  
  # creates a folder
  post '/folders' do
    content_type :json
    begin
      status 201
      settings.adapter.create_folder(params).to_json
    rescue StandardError => err
      logger.error err
      status 422
      { status: 422, message: err.message }.to_json
    end
  end
  
  # returns the specific folder
  get '/folders/:folder_id' do
    content_type :json
    begin
      status 200
      settings.adapter.folders(params[:folder_id]).to_json
    rescue StandardError => err
      logger.error err
      status 404
      { status: 404, message: err.message }
    end
  end
  
  delete '/folders/:folder_id' do
    begin
      status 204
      settings.adapter.delete_folder(params[:folder_id])
    rescue StandardError => err
      logger.error err
      status 404
      { status: 404, message: err.message }
    end
  end
  
  # returns the specific folder
  get '/folders/:folder_id/files' do
    content_type :json
    begin
      status 200
      settings.adapter.files(params[:folder_id]).to_json
    rescue StandardError => err
      logger.error err
      status 404
      { status: 404, message: err.message }
    end
  end
  
  # upload a file to the specific folder
  post '/folders/:folder_id/files' do
    content_type :json
    begin
      status 201
      settings.adapter.create_file(params[:folder_id], params[:file]).to_json
    rescue StandardError => err
      logger.error err
      status 422
      { status: 422, message: err.backtrace.join("\n") }.to_json
    end
  end
  
  # download
  get '/download/folders/:folder_id/files/:file_id' do
    halt 401, '<h1>Unauthorized</h1>' unless logged_in? || valid_token?
    begin
      file, content = settings.adapter.download_file(params[:folder_id], params[:file_id])
      content_type 'application/octet-stream'
      attachment file.name
      status 200
      content
    rescue StandardError => err
      logger.error err
      content_type :text
      status 404
      { status: 404, message: err.message }
    end
  end
  
  # generate token
  get '/folders/:folder_id/files/:file_id/token' do
    content_type :json
    begin
      status 200
      settings.adapter.token(params[:folder_id], params[:file_id]).to_json
    rescue StandardError => err
      logger.error err
      content_type :text
      status 404
      { status: 404, message: err.message }
    end
  end
  
  delete '/folders/:folder_id/files/:file_id' do
    begin
      status 204
      settings.adapter.delete_file(params[:folder_id], params[:file_id])
    rescue StandardError => err
      logger.error err
      status 404
      { status: 404, message: err.message }
    end
  end
end