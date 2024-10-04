require 'sinatra'
require 'httparty'
require '/manager.rb'
$ifc = Ifc::Manager.new('http://localhost:4567', 'ms1.pem')

configure do
  set :port, 3000 + ENV["NUMBER"].to_i
end


post '/receive-data' do
  response = nil
  to_send = params[:data]
  if ENV["NUMBER"].to_i < 4
    to_send = $ifc.add_integrity(params[:data], ["tag#{ENV["NUMBER"]}_int".to_sym])
    response = HTTParty.post("http://localhost:300#{(ENV["NUMBER"].to_i + 1)}/receive-data",
    body: {
      data: to_send,
    })
  else
    raise RuntimeError.new unless $ifc.check_integrity(to_send)
  end
  response&.body || to_send
end