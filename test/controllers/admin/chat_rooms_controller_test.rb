require "test_helper"

class Admin::ChatRoomsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin_user)
    sign_in @admin
  end

  test "should get index" do
    get admin_chat_rooms_url
    assert_response :success
  end

  # test "should get new" do
  #   get new_admin_chat_room_url
  #   assert_response :success
  # end

  # test "should create chat_room" do
  #   post admin_chat_rooms_url, params: { chat_room: { name: "New Room" } }
  #   assert_response :redirect
  # end
end
