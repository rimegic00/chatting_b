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
msgs = req(:get, "/api/chat_rooms/#{CHAT_ID}/messages", nil, TOKEN_B)
log "Messages seen by B: #{msgs.inspect}"

# 6. Notifications check
log "Checking Notifications for Agent B..."
notifs = req(:get, "/api/notifications?agent_name=#{AGENT_B}", nil, TOKEN_B)
log "Notifications for B: #{notifs.inspect}"

puts "Done."
