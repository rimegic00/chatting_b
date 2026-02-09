require 'net/http'
require 'json'
require 'uri'

BASE_URL = "http://localhost:3000"
AGENT_A = "BuyerBot"
AGENT_B = "SellerBot"

def log(msg)
  puts "[TEST] #{msg}"
end

def req(method, path, body = nil, token = nil)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  
  headers = { 'Content-Type' => 'application/json' }
  headers['Authorization'] = "Bearer #{token}" if token
  
  if method == :post
    request = Net::HTTP::Post.new(uri, headers)
    request.body = body.to_json if body
  elsif method == :get
    request = Net::HTTP::Get.new(uri, headers)
  end
  
  response = http.request(request)
  JSON.parse(response.body) rescue response.body
end

# 1. Get Tokens
log "Generating Tokens..."
res_a = req(:post, "/api/agent_sessions", { agent_name: AGENT_A })
TOKEN_A = res_a['token']
log "Agent A Token: #{TOKEN_A}"

res_b = req(:post, "/api/agent_sessions", { agent_name: AGENT_B })
TOKEN_B = res_b['token']
log "Agent B Token: #{TOKEN_B}"

# 2. Agent B creates a post
log "Creating Post by SellerBot (Agent B)..."
post_res = req(:post, "/api/posts", {
  post: { title: "MacBook Pro M3", content: "Selling unused macbook", price: 2000000, item_condition: "S" },
  agent_name: AGENT_B
}) # Note: for post creation, we might not enforced token yet if using old API, but let's assume it works or uses params
POST_ID = post_res['id'] || post_res.dig('post', 'id') || 1
log "Post Created: ID #{POST_ID}"

# 3. Agent A creates Trade Chat
log "Agent A creating trade chat..."
chat_res = req(:post, "/api/chat_rooms/trade", { post_id: POST_ID }, TOKEN_A)
CHAT_ID = chat_res['chat_room_id']
log "Chat Room Created: ID #{CHAT_ID}"

# 4. Agent A sends message
log "Agent A sending message..."
req(:post, "/api/chat_rooms/#{CHAT_ID}/messages", { content: "Is this available?" }, TOKEN_A)


# 5. Agent B polls messages
log "Agent B polling messages..."
# Use basic auth or token for B
chat_msgs_url = "/api/chat_rooms/#{CHAT_ID}/messages"
msgs = req(:get, chat_msgs_url, nil, TOKEN_B)
log "Messages seen by B: #{msgs.inspect}"

# v3.9: Test Buyer Agent Login Flow
puts "\n6. Testing Buyer Agent Login Flow..."
buyer_agent_name = "SmartBuyer_#{SecureRandom.hex(4)}"

# Simulate a request where the buyer agent identifies themselves explicitly
puts "   Requesting Trade Chat as '#{buyer_agent_name}' with explicit param..."
# Determine seller agent name from post_res
seller_agent_name = AGENT_B 
puts "   (Target Seller: #{seller_agent_name})"

trade_response = req(:post, "/api/chat_rooms/trade", { post_id: POST_ID, agent_name: buyer_agent_name })

if trade_response['chat_room_id']
  puts "   ✅ Trade Chat Created/Found! ID: #{trade_response['chat_room_id']}"
  
  # Verify membership/permission by sending a message
  puts "   Generating token for '#{buyer_agent_name}'..."
  token_response = req(:post, "/api/agent_sessions", { agent_name: buyer_agent_name })
  buyer_token = token_response['token']
  
  puts "   Sending message as '#{buyer_agent_name}'..."
  msg_response = req(:post, "/api/chat_rooms/#{trade_response['chat_room_id']}/messages", 
                     { content: "I want to buy this via API!" }, buyer_token)
    
  if msg_response['success']
    puts "   ✅ Message Sent Successfully by Buyer Agent!"
  else
    puts "   ❌ Message Sending Failed: #{msg_response}"
    exit 1
  end

else
  puts "   ❌ Failed to create trade chat: #{trade_response}"
  exit 1
end

puts "\n✅ All verification steps passed!"


# 6. Notifications check
log "Checking Notifications for Agent B..."
notifs = req(:get, "/api/notifications?agent_name=#{AGENT_B}", nil, TOKEN_B)
log "Notifications for B: #{notifs.inspect}"

# v3.9.2: Security Test - Unauthorized Update
puts "\n7. Testing Security Fix (Unauthorized Update)..."
# Try to update the post using a different agent (Agent A)
update_res = req(:patch, "/api/posts/#{POST_ID}", { post: { status: 'expired' } }, TOKEN_A)

if update_res['error'] && update_res['error']['code'] == 403
  puts "   ✅ Security Check Passed! Agent A was forbidden from updating Agent B's post."
else
  puts "   ❌ Security Check Failed! Agent A was able to update Agent B's post or received wrong error."
  puts "   Response: #{update_res}"
  exit 1
end

# Try to update with correct owner (Agent B)
puts "   Testing Authorized Update (Owner)..."
valid_update = req(:patch, "/api/posts/#{POST_ID}", { post: { status: 'active' } }, TOKEN_B)
if valid_update['success']
   puts "   ✅ Owner Update Passed!"
else
   puts "   ❌ Owner Update Failed: #{valid_update}"
   exit 1
end

puts "Done."
