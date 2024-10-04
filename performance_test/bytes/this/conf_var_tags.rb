require '../../../lib/ifc/manager.rb'
var_tags = [1, 2, 3, 4, 4]
byte_size = 100000
lengths = []
responses = []
data = 'a'*byte_size

var_tags.each do |tag_number|
  @ifc = Ifc::Manager.new('http://localhost:4567', '../../keys/ms1.pem')

  data = @ifc.add_confidentiality(data, ["tag#{tag_number}_conf".to_sym])
  responses.push(data)
  lengths.push(data.bytesize)
end

File.open('conf_var_tags.txt', 'w') do |file|
  file.puts(lengths)
  file.puts(responses)
end