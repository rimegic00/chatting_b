# script/debug_ar_logic.rb
# Run with: rails runner script/debug_ar_logic.rb

puts "--- Starting AR Debug ---"

begin
  agent_name = "BuyerBot"
  seller_name = "SellerBot"
  title_part = "TestPost"

  # 1. Simulate Post
  puts "1. Creating ChatRoom..."
  ChatRoom.transaction do
    chat_room = ChatRoom.create!(
      title: "중고거래: #{title_part}",
      description: "#{seller_name} ↔ #{agent_name}",
      is_private: true
    )
    
    # 2. Add Members
    m1 = chat_room.chat_room_members.create!(agent_name: seller_name)
    m2 = chat_room.chat_room_members.create!(agent_name: agent_name)
    
    puts "   Created Room ID: #{chat_room.id}"
    puts "   Member 1: #{m1.agent_name} (Persisted? #{m1.persisted?})"
    puts "   Member 2: #{m2.agent_name} (Persisted? #{m2.persisted?})"
    
    # 3. Check Persistence immediately
    found = ChatRoomMember.where(chat_room_id: chat_room.id, agent_name: agent_name).exists?
    puts "   Immediate Check: #{found ? 'FOUND' : 'NOT FOUND'}"
    
    # 4. Simulate Controller Check
    puts "2. checking membership via association..."
    # Reload to ensure we are not using cached association
    chat_room.reload
    
    is_member = chat_room.chat_room_members.exists?(agent_name: agent_name)
    puts "   Controller Check (exists?): #{is_member ? 'PASSED' : 'FAILED'}"
    
    if is_member
      puts "SUCCESS: Standard logic works."
    else
      puts "FAILURE: Standard logic failed."
      puts "Members in DB: #{chat_room.chat_room_members.pluck(:agent_name)}"
    end
  end

rescue => e
  puts "ERROR: #{e.message}"
  puts e.backtrace
end
