require 'openssl'
require 'redis'
require 'securerandom'
require 'base64'
require 'json'
require 'digest'
require 'yaml'
require 'puma'

class ChangedSecurityStringError < StandardError; end
class NoKeyOnDatabaseError < StandardError; end
class NotPresentOnAlltagsError < StandardError; end
class IntegritySignatureError < StandardError; end

class Authority
  def initialize
    redis_host = ENV["REDIS_HOST"] || "localhost"
    @redis = Redis.new(host: redis_host)
    if ENV["PRIVATE_KEY_PATH"]
      @key_pair = OpenSSL::PKey::RSA.new(File.open(ENV["PRIVATE_KEY_PATH"]))
    else
      @key_pair = OpenSSL::PKey::RSA.generate(ENV["KEY_SIZE"] || 2048)
    end
    @redis.del("security_string")
    generate_security_string
  end

  def reload_database
    @redis.flushall
    ifc_config = YAML.load_file('ifc_config.yml')
    ifc_config.each do |_, key_tags|
      @redis.set(File.read(key_tags["key"]), key_tags["tags"])
    end
  end

  def public_key
    @key_pair.public_key
  end

  def security_string
    string = @redis.get("security_string")
    if string.nil?
      generate_security_string
      return security_string
    end
    string
  end

  def remove_confidentiality!(signed_identity, public_key, data)
    simmetric_decryption_algorithm = ENV["SIMMETRIC_DESCRYPTION_ALGORITHM"] || "AES-256-CBC"
    decrypted = decrypt(data, simmetric_decryption_algorithm)
    check_ms_tags(signed_identity, public_key, decrypted[:confidentiality_tags])
    return {data: decrypted[:data], integrity_tags: decrypted[:integrity_tags],
      signature: signature_for(decrypted[:data], decrypted[:integrity_tags])}.to_json
  end

  def add_integrity!(signed_identity, public_key, data, integrity_tags)
    check_ms_tags(signed_identity, public_key, integrity_tags)
    hash = to_hash(data)
    if hash && (hash[:signature] || hash[:authority_metadata_depth])
      check_integrity! hash
      hash[:integrity_tags] = (hash[:integrity_tags] || []) + integrity_tags
      hash[:signature] = signature_for(hash[:data], hash[:integrity_tags])
      hash.to_json
    else
      {data: data, integrity_tags: integrity_tags, signature: signature_for(data, integrity_tags)}.to_json
    end
  end

  private

  def generate_security_string
    @redis.set("security_string", SecureRandom.base64(ENV["SECURITY_STRING_LENGTH"] || 20),
      ex: (ENV["SECURITY_STRING_EX"] || 3600))
  end

  def simmetric_decryption(data, simmetric_decryption_algorithm)
    cipher = OpenSSL::Cipher.new(simmetric_decryption_algorithm)
    cipher.decrypt
    cipher.key = data[:key]
    cipher.iv = data[:iv]
    data = Base64.decode64(data[:data])
    cipher.update(data) + cipher.final
  end

  def decrypt_key_and_iv(data)
    data[:key] = @key_pair.private_decrypt(Base64.decode64(data[:key]))
    data[:iv] = @key_pair.private_decrypt(Base64.decode64(data[:iv]))
    data
  end

  def check_integrity!(data_hash)
    return unless data_hash[:signature] || data_hash[:integrity_tags]

    begin
      data_hash[:signature] = Base64::decode64(data_hash[:signature])
      raise unless sha_for(data_hash[:data], data_hash[:integrity_tags]) == @key_pair.public_decrypt(data_hash[:signature])
    rescue StandardError
      raise IntegritySignatureError.new
    end
  end

  def decrypt(data, simmetric_decryption_algorithm, confidentiality_tags=[], integrity_tags=[])
    data_hash = decrypt_key_and_iv(JSON.parse(data, symbolize_names: true))
    check_integrity!(data_hash)
    decrypted_data = simmetric_decryption(data_hash, simmetric_decryption_algorithm)
    decrypted_data_hash = JSON.parse(decrypted_data, symbolize_names: true)
    decrypted_data_hash[:confidentiality_tags] = [] unless decrypted_data_hash[:confidentiality_tags]
    data_hash[:integrity_tags] = [] unless data_hash[:integrity_tags]
    decrypted_data_hash[:confidentiality_tags].push(*confidentiality_tags)
    data_hash[:integrity_tags].push(*integrity_tags)
    return decrypted_data_hash.merge({integrity_tags: data_hash[:integrity_tags]}) if data_hash[:authority_metadata_depth] == 1
    decrypt(decrypted_data_hash[:data], simmetric_decryption_algorithm, decrypted_data_hash[:confidentiality_tags], data_hash[:integrity_tags])
  end

  def check_ms_tags(signed_identity, public_key, resource_tags)
    key_object = OpenSSL::PKey::RSA.new(public_key)
    decrypted_security_string = key_object.public_decrypt(signed_identity)
    raise ChangedSecurityStringError unless decrypted_security_string == security_string
    if @redis.get(public_key)
      tags_from_db = eval(@redis.get(public_key))
    else
      raise NoKeyOnDatabaseError
    end
    return true if resource_tags.all? {|resource_tag| tags_from_db.include? resource_tag}
    raise NotPresentOnAlltagsError
  end

  def to_hash data
    begin
      JSON.parse(data, symbolize_names: true)
    rescue JSON::ParserError
      nil
    end
  end

  def sha_for(data, integrity_tags)
    "#{Digest::SHA2.hexdigest(data)}#{integrity_tags.join("")}"
  end

  def signature_for(data, integrity_tags)
    Base64::encode64(@key_pair.private_encrypt(sha_for(data, integrity_tags)))
  end
end