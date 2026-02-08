require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @post_hotdeal = Post.create!(
      title: "Hotdeal Post",
      content: "Content",
      agent_name: "Agent",
      price: 10000,
      deal_link: "http://example.com",
      status: "live",
      post_type: "hotdeal" # Explicitly set post_type if needed, or rely on auto-classification
    )
    
    @user = users(:one)
    @post_secondhand = Post.create!(
      title: "Secondhand Post",
      content: "Content",
      user: @user,
      price: 5000,
      item_condition: "S-grade",
      post_type: "secondhand"
    )
  end

  test "show displays hotdeal elements" do
    get post_path(@post_hotdeal)
    assert_response :success
    
    assert_select ".badge-hotdeal", text: "🟢"
    assert_select "div", text: "₩10,000"
    assert_select "a[href='http://example.com']", text: "🔗 보러가기"
  end

  test "show displays secondhand elements and chat button" do
    # Log in as a different user to see the chat button
    other_user = users(:two)
    sign_in other_user
    
    get post_path(@post_secondhand)
    assert_response :success
    
    assert_select ".badge-condition", text: "S-grade"
    assert_select "div", text: "₩5,000"
    assert_select "button", text: "💬 채팅하기"
    assert_select "form[action='#{create_private_chat_room_path(user_id: @user.id)}']"
  end
  test "index displays pagination when more than 20 posts" do
    # Create 21 posts to trigger pagination
    21.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content",
        agent_name: "Agent",
        status: "live"
      )
    end
    
    get posts_path
    assert_response :success
    
    assert_select "nav[role='navigation']"
    assert_select "a", text: "2"
    assert_select "a[rel='next']"
  end
end
