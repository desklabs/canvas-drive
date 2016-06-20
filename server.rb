require 'sinatra'
require 'json'
require 'base64'
require 'openssl'

configure do
  enable :sessions, :logging
  
  set :force_ssl, true
  set :protection, frame_options: "ALLOW-FROM #{ENV['DESK_DOMAIN']}"
  set :port, ENV['PORT'] || 3000
  set :bind, ENV['IP'] || '0.0.0.0'
  set :session_secret, ENV['SESSION_SECRET']
  set :public_folder, File.dirname(__FILE__) + '/public'
  
  require_relative "adapters/#{ENV['ADAPTER']}"
  klass_name = ENV['ADAPTER'].split('_').collect!{ |w| w.capitalize }.join
  set :adapter, Object.const_get(klass_name).new
end

configure :development do
  enable :dump_errors, :raise_errors, :show_exceptions
  set :host, 'drive-tstachl-1.c9users.io'
end

helpers do
  def parse_signed_request(request, max_age=3600)
    encoded_sig, enc_envelope = request.split('.', 2)
    envelope = JSON.parse(base64_decode(enc_envelope), symbolize_names: true)
    algorithm = envelope[:algorithm]

    raise 'Invalid request. (Unsupported algorithm.)' \
      if algorithm != 'HMACSHA256'

    raise 'Invalid request. (Too old.)' \
      if Time.parse(envelope[:issuedAt]).to_i < Time.now.to_i - max_age

    hex = OpenSSL::HMAC.hexdigest('sha256', ENV['SHARED_KEY'], enc_envelope).split.pack('H*')
    raise 'Invalid request. (Invalid signature.)' \
      if base64_decode(encoded_sig) != hex

    envelope
  end
  
  def base64_decode(str)
    str += '=' * (4 - str.length.modulo(4))
    Base64.decode64(str.tr('-_','+/'))
  end
end

before do
  if settings.force_ssl && !request.secure?
    halt 400, "<h1>Please use SSL at https://#{settings.host}</h1>"
  end
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

post '/login' do
  redirect '/'
end

get '/' do
  erb :index
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

