require 'httparty'
require 'json'
require 'base64'

@public_key = OpenSSL::PKey::RSA.new(File.open('../../keys/ms1_public.pem'))

def simmetric_encryption(data)
  cripter = OpenSSL::Cipher.new('AES-256-CBC')
  cripter.encrypt
  cripter.key = key = cripter.random_key
  cripter.iv = iv = cripter.random_iv
  {key: key, iv: iv, data: Base64.encode64(cripter.update(data) + cripter.final)}
end

def encrypt_key_and_iv(data)
  data[:key] = Base64.encode64(@public_key.encrypt(data[:key]))
  data[:iv] = Base64.encode64(@public_key.encrypt(data[:iv]))
  data
end

def encrypt(data)
  data_hash = simmetric_encryption(data.to_json)
  data_hash = encrypt_key_and_iv(data_hash)
  data_hash
end

test_case = [1, 10, 100, 1000, 10000, 100000]
lengths = []
responses = []
test_case.each do |bytes|
  data = 'a'*bytes
  data = encrypt(data).to_json
  responses.push(data)
  lengths.push(data.bytesize)
end
File.open('some_conf.txt', 'w') do |file|
  file.puts(lengths)
  file.puts(responses)
end