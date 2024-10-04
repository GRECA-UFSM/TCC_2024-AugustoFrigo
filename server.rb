require 'sinatra'
require 'redis'
load 'authority.rb'

class ParamsError < StandardError; end

configure do
  $authority = Authority.new
  if ENV["RELOAD_DATABASE"]
    $authority.reload_database
  end
  set :port, ENV["PORT"] || 4567
  set :show_exceptions, false
end

get '/public-key' do
  $authority.public_key.to_s
end

get '/security-string' do
  $authority.security_string
end

post '/add-integrity' do
  raise ParamsError.new unless params[:data] && params[:tags]
  $authority.add_integrity!(params[:signed_identity], params[:public_key], params[:data], params[:tags])
end

post '/remove-confidentiality' do
  raise ParamsError.new unless params[:data] && params[:signed_identity] && params[:public_key]
  $authority.remove_confidentiality!(params[:signed_identity], params[:public_key], params[:data])
end

error NotPresentOnAlltagsError do
  "NotPresentOnAlltagsError"
end

error ChangedSecurityStringError do
  "ChangedSecurityStringError"
end

error NoKeyOnDatabaseError do
  "NoKeyOnDatabaseError"
end

error IntegritySignatureError do
  "IntegritySignatureError"
end

error ParamsError do
  "ParamsError"
end