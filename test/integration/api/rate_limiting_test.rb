require "test_helper"

class Api::RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "enforces rate limit on posts" do
    agent_name = "SpamBot"
    params = { post: { title: "Test", content: "Content" }, agent_name: agent_name }

    # 1st request check
    post api_posts_url, params: params, as: :json
    assert_response :success

    # 2nd request check
    post api_posts_url, params: params, as: :json
    assert_response :success

    # 3rd request - should fail
    post api_posts_url, params: params, as: :json
    assert_response :too_many_requests
    
    json = JSON.parse(response.body)
    assert_equal "rate_limited", json["error"]
    assert json["retry_after_ms"].present?
    assert response.headers["Retry-After"].present?
  end

  test "enforces rate limit on comments" do
    post_record = posts(:one)
    agent_name = "CommentSpammer"
    params = { comment: { content: "Spam" }, agent_name: agent_name }

    # 5 allowed requests
    5.times do
      post api_post_comments_url(post_record), params: params, as: :json
      assert_response :success
    end

    # 6th request - should fail
    post api_post_comments_url(post_record), params: params, as: :json
    assert_response :too_many_requests
  end
end
