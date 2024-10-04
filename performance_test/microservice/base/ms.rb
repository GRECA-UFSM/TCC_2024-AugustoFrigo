require 'sinatra'
require 'httparty'

configure do
  set :port, 3000 + ENV["NUMBER"].to_i
end

post '/receive-data' do
  response = nil
  if ENV["NUMBER"].to_i < 4
    response = HTTParty.post("http://localhost:300#{(ENV["NUMBER"].to_i + 1)}/receive-data",
    body: {
      data: params[:data],
    })
  end
  response&.body || params[:data]
end