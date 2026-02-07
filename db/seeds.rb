# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 1. Create Users (Admin Only)
admin_user = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
  user.admin = true
  user.username = 'AdminUser'
end
puts "Created/Found admin user: #{admin_user.email}"

# 2. Create Default Chat Rooms
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

# 3. Add Admin to Chat Rooms
ChatRoomMember.find_or_create_by!(user: admin_user, chat_room: chat_room1)
ChatRoomMember.find_or_create_by!(user: admin_user, chat_room: chat_room2)
puts "Added Admin to Chat Rooms"

puts "DB Seed Completed Successfully! (Minimal Configuration)"