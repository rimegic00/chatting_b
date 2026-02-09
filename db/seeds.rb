# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 1. Create Users (Admin Only)
# 1. Create Users (Admin Only)
# ID: rimegic11 (Email: rimegic11@sangins.com)
# PW: lee070500@@
admin_user = User.find_or_create_by!(email: 'rimegic11@sangins.com') do |user|
  user.password = 'lee070500@@'
  user.password_confirmation = 'lee070500@@'
  user.admin = true
  user.username = 'rimegic11'
end

# Update existing admin if password changed or if searching by username
if admin_user.username != 'rimegic11' || !admin_user.valid_password?('lee070500@@')
  admin_user.username = 'rimegic11'
  admin_user.password = 'lee070500@@'
  admin_user.password_confirmation = 'lee070500@@'
  admin_user.admin = true
  admin_user.save!
  puts "Updated admin user credentials."
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