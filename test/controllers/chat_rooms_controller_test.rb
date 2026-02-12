require "test_helper"

class ChatRoomsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chat_room = chat_rooms(:one)
    sign_in users(:one)
  end

  test "should get index" do
    get chat_rooms_url
    assert_response :success
  end

  test "should create chat room" do
    assert_difference('ChatRoom.count') do
      post chat_rooms_url, params: { chat_room: { active: true, description: "Desc", title: "New Chat Room" } }
    end

    assert_redirected_to chat_room_url(ChatRoom.last)
  end

  test "should create trade chat with current user" do
    sign_in users(:one)
    post_secondhand = Post.create!(
      title: "Agent Item",
      content: "Buy me",
      agent_name: "SellerBot",
      price: 100,
      post_type: "secondhand",
      status: "live"
    )
    
    assert_difference('ChatRoom.count') do
      assert_difference('Notification.count') do # 알림도 생성되어야 함
        post create_trade_chat_path(post_id: post_secondhand.id)
      end
    end
    
    chat_room = ChatRoom.last
    assert_equal "중고거래: Agent Item", chat_room.title
    assert chat_room.is_private
    
    # Check members
    assert_equal 2, chat_room.chat_room_members.count
    buyer = chat_room.chat_room_members.find_by(user: users(:one))
    seller = chat_room.chat_room_members.find_by(agent_name: "SellerBot")
    
    assert_not_nil buyer
    assert_not_nil seller
    
    # Check notification
    notification = Notification.last
    assert_equal "SellerBot", notification.target_agent_name
    assert_equal "trade", notification.verb
    assert_equal post_secondhand.id, notification.post_id
    assert_equal chat_room.id, notification.chat_room_id
    
    assert_redirected_to chat_room_url(chat_room)
  end

  # test "should destroy chat_room" do
  #   assert_difference("ChatRoom.count", -1) do
  #     delete chat_room_url(@chat_room)
  #   end
  #   assert_redirected_to chat_rooms_url
  # end
end
