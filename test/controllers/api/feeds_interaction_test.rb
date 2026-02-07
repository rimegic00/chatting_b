require "test_helper"

class Api::FeedsInteractionTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @user = users(:one)
    # Ensure money type exists in enum for testing or mock it if needed 
    # (assuming enum update worked)
    @money_post = Post.create!(
      title: "Money Post", 
      content: "Rich content", 
      post_type: "money", 
      price: 1000,
      status: 'live'
    )
  end

  test "should get feeds by category" do
    get "/api/feeds/hotdeal"
    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "hotdeal", json["category"]

    get "/api/feeds/money"
    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "money", json["category"]
    
    # Verify the money post is included
    assert json["items"].any? { |item| item["title"] == "Money Post" }
  end

  test "should filter feeds by price" do
    get "/api/feeds/all?min_price=500&max_price=1500"
    assert_response :success
    json = JSON.parse(response.body)
    
    # Check if items are within price range
    json["items"].each do |item|
      price = item["meta"]["price"]
      if price
        assert price >= 500
        assert price <= 1500
      end
    end
  end

  test "should get nested comments" do
    # Create a comment chain
    parent = @post.comments.create!(content: "Parent", commenter_name: "ParentBot")
    child = @post.comments.create!(content: "Child", parent_id: parent.id, commenter_name: "ChildBot")

    get "/api/posts/#{@post.id}/comments"
    assert_response :success
    json = JSON.parse(response.body)
    
    assert json["success"]
    assert_equal @post.id, json["post_id"]
    
    # Find the parent comment in response
    parent_comment = json["comments"].find { |c| c["id"] == parent.id }
    assert_not_nil parent_comment
    assert_equal "Parent", parent_comment["content"]
    
    # Check nested reply
    assert_equal 1, parent_comment["replies"].length
    assert_equal "Child", parent_comment["replies"][0]["content"]
  end

  test "should create comment via API" do
    assert_difference("Comment.count") do
      post "/api/posts/#{@post.id}/comments", 
           params: { comment: { content: "New Comment" }, agent_name: "TesterBot" },
           as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "New Comment", json["comment"]["content"]
    assert_equal "TesterBot", json["comment"]["agent_name"]
  end

  test "should rate limit comments" do
    # Manually trigger rate limit
    ip = "127.0.0.1"
    key = "rate_limit:comments:#{ip}"
    
    # Clear cache first
    Rails.cache.delete(key)
    
    # Make 6 requests
    6.times do
      post "/api/posts/#{@post.id}/comments", 
           params: { comment: { content: "Spam" }, agent_name: "SpamBot" },
           as: :json
    end
    
    # The 6th request should fail
    assert_response :too_many_requests
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_equal "Too Many Requests", json["error"]
  end
end
