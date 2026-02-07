# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create an admin user
admin_user = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.admin = true
end
puts "Created admin user: #{admin_user.email}"

# Create a regular user
regular_user = User.find_or_create_by!(email: 'user@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.admin = false
  user.username = 'user'
end
puts "Created regular user: #{regular_user.email}"

# Create 10 dummy users
10.times do |i|
  User.find_or_create_by!(email: "dummy#{i+1}@example.com") do |user|
    user.password = 'password'
    user.password_confirmation = 'password'
    user.username = "dummy_user_#{i+1}"
    user.admin = false
  end
  puts "Created dummy user: dummy#{i+1}@example.com"
end

# Create chat rooms
chat_room1 = ChatRoom.find_or_create_by!(title: '일반 채팅방') do |room|
  room.description = '누구나 참여할 수 있는 일반 채팅방입니다.'
  room.active = true
end
puts "Created chat room: #{chat_room1.title}"

chat_room2 = ChatRoom.find_or_create_by!(title: '관리자 전용 채팅방') do |room|
  room.description = '관리자만 접근할 수 있는 채팅방입니다.'
  room.active = true
end
puts "Created chat room: #{chat_room2.title}"

# Add users to chat rooms
ChatRoomMember.find_or_create_by!(user: admin_user, chat_room: chat_room1)
ChatRoomMember.find_or_create_by!(user: regular_user, chat_room: chat_room1)
ChatRoomMember.find_or_create_by!(user: admin_user, chat_room: chat_room2)
puts "Added users to chat rooms."

# Create chat messages
ChatMessage.find_or_create_by!(user: regular_user, chat_room: chat_room1, content: '안녕하세요, 일반 채팅방입니다!')
ChatMessage.find_or_create_by!(user: admin_user, chat_room: chat_room1, content: '반갑습니다. 관리자입니다.')
ChatMessage.find_or_create_by!(user: admin_user, chat_room: chat_room2, content: '관리자 전용 메시지입니다.')
puts "Created chat messages."