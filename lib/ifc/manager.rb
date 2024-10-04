require 'openssl'
require 'redis'
require 'securerandom'
require 'base64'
require 'json'
require 'digest'
require 'httparty'

module Ifc
  class InvalidAuthorityError < StandardError; end
  class NotPresentOnAlltagsError < StandardError; end
  class ParamsError < StandardError; end
  class NoKeyOnDatabaseError < StandardError; end
  class ChangedSecurityStringError < StandardError; end
  class IntegritySignatureError < StandardError; end

  class Manager
    def initialize(authority_url, key_pair_path, assimetric_key_size=2048, simmetric_encryption_algorithm='AES-256-CBC')
      @authority_url = authority_url
      response = HTTParty.get(@authority_url + '/public-key')
      if response.ok?
        @authority_cipher = OpenSSL::PKey::RSA.new(response.body)
      else
        raise InvalidAuthorityError.new
      end
      @simmetric_encryption_algorithm = simmetric_encryption_algorithm
      @key_pair = OpenSSL::PKey::RSA.new(File.open(key_pair_path))
      get_set_security_string
    end

    def add_confidentiality(data, confidentiality_tags)
      hash = to_hash data
      if hash && hash[:authority_metadata_depth]
        encrypt({data:, confidentiality_tags: confidentiality_tags}).merge({authority_metadata_depth: hash[:authority_metadata_depth] + 1}).to_json
      else
        encrypt({data:, confidentiality_tags: confidentiality_tags}).merge({authority_metadata_depth: 1}).to_json
      end
    end

    def remove_confidentiality(data, tags=nil)
      response = HTTParty.post(@authority_url + '/remove-confidentiality',
        body: {
          signed_identity: sign(@security_string),
          data:,
          public_key: @key_pair.public_key.to_s
        })
      return response.body if response.success?
      handle_authority_errors(response.body, data, nil, __method__)
    end

    def add_integrity(data, tags)
      response = HTTParty.post(@authority_url + '/add-integrity',
        body: {
          signed_identity: sign(@security_string),
          data:,
          public_key: @key_pair.public_key.to_s,
          tags:
        })
      return response.body if response.success?
      handle_authority_errors(response.body, data, tags, __method__)
    end

    def check_integrity(data)
      hash = JSON.parse(data, symbolize_names: true)
      hash[:signature] = Base64::decode64(hash[:signature])
      "#{Digest::SHA2.hexdigest(hash[:data])}#{hash[:integrity_tags].join("")}" == @authority_cipher.public_decrypt(hash[:signature])
    end

    def remove_integrity(data)
      return_hash = JSON.parse(data, symbolize_names: true)
      return_hash.delete(:integrity_tags)
      return_hash.delete(:signature)
      return_hash.to_json
    end
    
    private

    def get_set_security_string
      @security_string = HTTParty.get(@authority_url + '/security-string')
    end

    def simmetric_encryption(data)
      cripter = OpenSSL::Cipher.new(@simmetric_encryption_algorithm)
      cripter.encrypt
      cripter.key = key = cripter.random_key
      cripter.iv = iv = cripter.random_iv
      {key: key, iv: iv, data: Base64.encode64(cripter.update(data) + cripter.final)}
    end

    def encrypt_key_and_iv(data)
      data[:key] = Base64.encode64(@authority_cipher.encrypt(data[:key]))
      data[:iv] = Base64.encode64(@authority_cipher.encrypt(data[:iv]))
      data
    end

    def encrypt(data)
      data_hash = simmetric_encryption(data.to_json)
      data_hash = encrypt_key_and_iv(data_hash)
      data_hash
    end

    def to_hash data
      begin
        JSON.parse(data, symbolize_names: true)
      rescue JSON::ParserError
        nil
      end
    end

    def handle_authority_errors(error, data, tags, action)
      case error
      when "NotPresentOnAlltagsError", "ParamsError", "NoKeyOnDatabaseError", "IntegritySignatureError"
        raise Object.const_get("Ifc::#{error}").new
      when "ChangedSecurityStringError"
        get_set_security_string
        self.send(action, data, tags)
      else
        raise StandardError.new(error)
      end
    end

    def change_key
      @key_pair = authority.change_key!
    end

    def sign(security_string)
      @key_pair.private_encrypt(security_string)
    end

    def key_pair
      @key_pair
    end
  end
end
