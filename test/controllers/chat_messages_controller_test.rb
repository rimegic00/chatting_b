require "test_helper"

class ChatMessagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get chat_messages_create_url
    assert_response :success
  end
end
