module ClientHelper
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
  
  def logged_in?
    session && session.key?(:signed_request)
  end
  
  def valid_token?
    settings.adapter.validate_token(params[:token], params[:folder_id], params[:file_id])
  end
  
  def create_case
    file = settings.adapter.create_file("tmp", params[:case_attachment][:attachment])
    first_name, last_name = parse_name(params[:interaction][:name])
    
    Resque.enqueue(CreateCaseJob, {
      file: file,
      first_name: first_name,
      last_name: last_name,
      email: params[:interaction][:email],
      subject: params[:email][:subject],
      body: params[:email][:body]
    })
  end
  
  def parse_name(name)
    name = Namae.parse(name).first
    [name.given, name.family]
  end
end
