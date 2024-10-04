require 'httparty'

data = "a"*ENV["STRING_SIZE"].to_i
start_measure = Process.clock_gettime(Process::CLOCK_MONOTONIC)
response = HTTParty.post("http://localhost:3001/receive-data",
    body: {
      data:,
    })
end_measure = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Execution time: #{end_measure - start_measure}"
puts response