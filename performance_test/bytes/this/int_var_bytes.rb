require '../../../lib/ifc/manager.rb'
test_case = [1, 10, 100, 1000, 10000, 100000]
lengths = []
responses = []
test_case.each do |bytes|
  data = 'a'*bytes
  @ifc = Ifc::Manager.new('http://localhost:4567', '../../keys/ms1.pem')

  data = @ifc.add_integrity(data, [:tag1_int])
  data = @ifc.add_integrity(data, [:tag2_int])
  data = @ifc.add_integrity(data, [:tag3_int])
  responses.push(data)
  lengths.push(data.bytesize)
end

File.open('int_var_bytes.txt', 'w') do |file|
  file.puts(lengths)
  file.puts(responses)
end