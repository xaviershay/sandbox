require 'net/http'
require 'json'
require 'uri'

uri = URI.parse("https://sa6mifk9pb.execute-api.us-east-1.amazonaws.com/solveLP")
filename = ARGV.fetch(0)

contents = JSON.parse(File.read(filename)) # Ensure valid
expected = contents['expected']

problem = if expected
  contents['problem']
else
  contents
end



header = {}
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri, header)
request.body = problem.to_json

response = http.request(request)

json_resp = JSON.parse(response.body)
if expected && json_resp["variables"] != expected
  puts "=== EXPECTED ===\n"
  puts JSON.pretty_generate(expected)
  puts
  puts "=== ACTUAL ===\n"
  puts JSON.pretty_generate(json_resp['variables'])

  exit 1
else
  puts JSON.pretty_generate(json_resp)
end
