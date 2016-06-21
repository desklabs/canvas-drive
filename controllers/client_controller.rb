require_relative 'application_controller'

class ClientController < ApplicationController
  helpers ClientHelper
  
  configure :production, :development do
    set :protection, frame_options: "ALLOW-FROM #{ENV['DESK_DOMAIN']}"
    clazz = ENV['ADAPTER'].split('_').collect!{ |w| w.capitalize }.join
    set :adapter, Object.const_get(clazz).new
  end
  
  before do
    if request.post? && params[:signed_request]
      session[:signed_request] = parse_signed_request(params[:signed_request])
    end
  end
  
  before /^\/(?!login)/ do
    if !session.key?(:signed_request)
      halt 401, '<h1>Unauthorized</h1>'
    end
  end
  
  get '/' do
    title "File Explorer"
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
      status 404
      { status: 404, message: err.message }
    end
  end
  
  delete '/folders/:folder_id' do
    begin
      status 204
      settings.adapter.delete_folder(params[:folder_id])
    rescue StandardError => err
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
      status 422
      { status: 422, message: err.message }.to_json
    end
  end
  
  # download
  get '/folders/:folder_id/files/:file_id' do
    begin
      content_type 'application/octet-stream'
      status 200
      settings.adapter.download_file(params[:folder_id], params[:file_id])
    rescue StandardError => err
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
      status 404
      { status: 404, message: err.message }
    end
  end
end