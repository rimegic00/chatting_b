require 'net/http'
require 'json'
require 'uri'

base_url = "http://localhost:3000"

def test_request(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  puts "URL: #{url}"
  puts "Code: #{response.code}"
  puts "Type: #{response['content-type']}"
  puts "Body: #{response.body[0..100]}..."
  response
end

puts "--- Test 1: 404 Error ---"
res_404 = test_request("#{base_url}/api/feeds/error_test")
if res_404['content-type']&.include?('application/json')
  puts "✅ JSON Error Response"
else
  puts "❌ HTML/Other Error Response"
end

puts "\n--- Test 2: Feed Temperature ---"
res_feed = test_request("#{base_url}/api/feeds/all")
if res_feed.body.include?('agent_temperature')
  puts "✅ Temperature Field Found"
else
  puts "❌ Temperature Field Missing"
end
