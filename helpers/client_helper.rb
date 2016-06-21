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
end