require "test_helper"

class CommentUserTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  test "comment created by logged in user should have user_id" do
    @user.update!(username: "")
    sign_in @user
    
    post post_comments_path(@post), params: {
      comment: {
        content: "Test comment",
        commenter_name: "Ignored Name" 
      }
    }, as: :turbo_stream
    
    assert_response :success
    # The default partial rendering should contain the user indicator
    assert_select "turbo-stream[action='append'][target='comments'] template" do
      # Expect 2 green texts: 1 for Author, 1 for Reply Form
      assert_select ".text-green-400", count: 2
      assert_select "div", text: /👤/
    end
    
    comment = Comment.last 
    
    # In the full page reload (get post_path)
    get post_path(@post)
    assert_response :success
    
    # 1. Verify MAIN Comment Form has "Logged in as" indicator
    assert_select "#comment_#{@post.id}_form .text-green-400", count: 1
    
    # 2. Verify NEW Comment has 2 green items (Author + Reply Form)
    assert_select "#comment_#{comment.id} .text-green-400", count: 2
    assert_select "#comment_#{comment.id}", text: /👤/
    # Expect email part since username is empty string in fixture
    expected_name = @user.email.split('@').first
    assert_select "#comment_#{comment.id}", text: /#{expected_name}/
    
    # Verify the form shows "Logged in as"
    assert_select "form" do
      assert_select "div", text: /로그인됨/
      assert_select "div", text: /#{expected_name}/
    # Verify is_human flag is set
    assert comment.is_human?, "Comment created via Web UI should be marked as human"
  end
  end

  test "anonymous comment created via Web UI should be marked as human" do
    post post_comments_path(@post), params: {
      comment: {
        content: "Anonymous Human Comment",
        commenter_name: "Real Person" 
      }
    }
    
    assert_response :redirect
    follow_redirect!
    assert_response :success
    
    comment = Comment.last
    assert_nil comment.user
    assert comment.is_human?, "Anonymous Web comment should be marked as human"
    
    # Verify Visual Indicator
    # 1. New Comment (Author ONLY) = 1 green item. Reply Form is not green for anonymous.
    assert_select "#comment_#{comment.id} .text-green-400", count: 1
    assert_select "#comment_#{comment.id}", text: /👤/
    assert_select "#comment_#{comment.id}", text: /Real Person/
  end
end
