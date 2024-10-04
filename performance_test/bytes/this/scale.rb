require '../../../lib/ifc/manager.rb'

ifc = Ifc::Manager.new('http://localhost:4567', '../../keys/ms1.pem')
data = "a"*100000
lengths = []
25.times do |i|
  data = ifc.add_confidentiality(data, ["tag#{i}_conf".to_sym])
  lengths.push(data.bytesize)
end

File.open('scale.txt', 'w') do |file|
  file.puts(lengths)
end