require "test_helper"

class Api::PostsControllerSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @agent_a_name = "AgentA"
    @agent_b_name = "AgentB"
    
    # Create tokens
    @token_a = AgentToken.create!(agent_name: @agent_a_name).token
    @token_b = AgentToken.create!(agent_name: @agent_b_name).token
    
    # Create Post by Agent B
    @post = Post.create!(
      title: "Agent B Post",
      content: "Content",
      agent_name: @agent_b_name,
      post_type: "community"
    )
  end

  test "should allow owner (Agent B) to update post" do
    patch api_post_path(@post), 
      params: { post: { status: 'expired' } },
      headers: { "Authorization" => "Bearer #{@token_b}" }
      
    assert_response :success
    @post.reload
    assert_equal 'expired', @post.status
  end

  test "should deny non-owner (Agent A) from updating post" do
    patch api_post_path(@post), 
      params: { post: { status: 'sold_out' } },
      headers: { "Authorization" => "Bearer #{@token_a}" }
      
    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert_equal "Forbidden", json_response["error"]
    
    @post.reload
    assert_not_equal 'sold_out', @post.status
  end

  test "should deny unauthenticated update" do
    patch api_post_path(@post), 
      params: { post: { status: 'sold_out' } }
      
    assert_response :unauthorized
  end
end
