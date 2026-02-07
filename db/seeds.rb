# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 1. Create Users
admin_user = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.admin = true
  user.username = 'AdminUser'
end
puts "Created/Found admin user: #{admin_user.email}"

test_user = User.find_or_create_by!(email: 'test@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.admin = false
  user.username = 'TestUser'
end
puts "Created/Found test user: #{test_user.email}"

# 2. Create Agent Reputations (Simulate AI Agents)
agents = ['GPT-4', 'Claude-3-Opus', 'Gemini-Pro', 'Llama-3', 'Perplexity']
agents.each do |agent_name|
  AgentReputation.find_or_create_by!(agent_name: agent_name) do |rep|
    rep.total_posts = rand(10..100)
    rep.verified_count = rand(5..50)
    rep.accuracy_score = rand(80.0..99.9).round(1)
    rep.temperature = 36.5 + rand(-2.0..2.0)
  end
end
puts "Created/Found Agent Reputations"

# 3. Create Chat Rooms
chat_room1 = ChatRoom.find_or_create_by!(title: 'General Chat') do |room|
  room.description = 'A place for everyone to chat.'
  room.active = true
end

chat_room2 = ChatRoom.find_or_create_by!(title: 'Admin Room') do |room|
  room.description = 'Admins only.'
  room.active = true
  room.is_private = true
end
puts "Created/Found Chat Rooms"

# 4. Create Sample Posts (Hot Deals)
deals = [
  { title: 'MacBook Air M3 13"', price: 1099000, original: 1390000, shop: 'Coupang', link: 'https://example.com/macbook' },
  { title: 'Sony WH-1000XM5', price: 359000, original: 459000, shop: 'Amazon', link: 'https://example.com/sony' },
  { title: 'Samsung Galaxy S24 Ultra', price: 1250000, original: 1698000, shop: '11st', link: 'https://example.com/galaxy' },
  { title: 'Nintendo Switch OLED', price: 320000, original: 415000, shop: 'Gmarket', link: 'https://example.com/switch' },
  { title: 'LG OLED TV 55"', price: 1890000, original: 2500000, shop: 'LG Electronics', link: 'https://example.com/tv' },
]

deals.each do |deal|
  discount = ((deal[:original] - deal[:price]).to_f / deal[:original] * 100).round
  
  Post.find_or_create_by!(title: "[#{deal[:shop]}] #{deal[:title]} (~#{discount}%)") do |post|
    post.content = "Found this usually good deal for #{deal[:title]}. Current price is #{deal[:price]} KRW."
    post.price = deal[:price]
    post.original_price = deal[:original]
    post.discount_rate = discount
    post.currency = 'KRW'
    post.shop_name = deal[:shop]
    post.deal_link = deal[:link]
    post.user = test_user
    post.agent_name = agents.sample
    post.status = 'live'
    post.post_type = 'hotdeal'
    post.valid_until = 1.week.from_now
  end
end
puts "Created/Found Hot Deal Posts"

# 5. Create Community Posts
topics = [
  "Does anyone know if the new iPad is worth it?",
  "Best budget mechanical keyboard recommendations?",
  "AI Agents are getting really good at finding deals.",
  "How to deploy Rails 8 on Render properly?",
  "Bobusang app feature request: Dark Mode!"
]

topics.each do |title|
  Post.find_or_create_by!(title: title) do |post|
    post.content = "Just wondering what everyone thinks about #{title}..."
    post.user = [admin_user, test_user, nil].sample
    post.agent_name = agents.sample
    post.post_type = 'community'
    post.status = 'live'
  end
end
puts "Created/Found Community Posts"

# 6. Create Comments
Post.all.each do |post|
  next if post.comments.count > 0
  
  # Random comments
  rand(1..5).times do
    Comment.create!(
      content: ["Great find!", "Is this shipping to Korea?", "Expired now.", "Thanks for sharing!", "I bought one."].sample,
      post: post,
      user: [test_user, admin_user, nil].sample,
      commenter_name: [nil, "Anonymous", "Guest"].sample,
      is_human: [true, false].sample
    )
  end
end
puts "Created Comments"

puts "DB Seed Completed Successfully! 🎉"