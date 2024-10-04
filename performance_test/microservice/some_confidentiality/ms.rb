require 'sinatra'
require 'httparty'
require 'json'
require 'base64'

configure do
  set :port, 3000 + ENV["NUMBER"].to_i
end

$public_key = OpenSSL::PKey::RSA.new(File.open('ms1_public.pem'))

def simmetric_encryption(data)
  cripter = OpenSSL::Cipher.new('AES-256-CBC')
  cripter.encrypt
  cripter.key = key = cripter.random_key
  cripter.iv = iv = cripter.random_iv
  {key: key, iv: iv, data: Base64.encode64(cripter.update(data) + cripter.final)}
end

def encrypt_key_and_iv(data)
  data[:key] = Base64.encode64($public_key.encrypt(data[:key]))
  data[:iv] = Base64.encode64($public_key.encrypt(data[:iv]))
  data
end

def encrypt(data)
  data_hash = simmetric_encryption(data.to_json)
  data_hash = encrypt_key_and_iv(data_hash)
  data_hash
end

$key_pair = OpenSSL::PKey::RSA.new(File.open('ms1.pem'))
def simmetric_decryption(data, simmetric_decryption_algorithm)
  cipher = OpenSSL::Cipher.new(simmetric_decryption_algorithm)
  cipher.decrypt
  cipher.key = data[:key]
  cipher.iv = data[:iv]
  data = Base64.decode64(data[:data])
  cipher.update(data) + cipher.final
end

def decrypt_key_and_iv(data)
  data[:key] = $key_pair.private_decrypt(Base64.decode64(data[:key]))
  data[:iv] = $key_pair.private_decrypt(Base64.decode64(data[:iv]))
  data
end

def decrypt(data)
  data_hash = decrypt_key_and_iv(JSON.parse(data, symbolize_names: true))
  decrypted_data = simmetric_decryption(data_hash, 'AES-256-CBC')
  decrypted_data_hash = JSON.parse(decrypted_data, symbolize_names: true)
end

post '/receive-data' do
  response = nil
  to_send = params[:data]
  to_send = encrypt(params[:data]).to_json if ENV["NUMBER"].to_i == 1
  if ENV["NUMBER"].to_i < 4
    response = HTTParty.post("http://localhost:300#{(ENV["NUMBER"].to_i + 1)}/receive-data",
    body: {
      data: to_send,
    })
  else
    decrypted = decrypt(params[:data])
  end
  response&.body || decrypted
end