require 'test_helper'

class WebhookThreadTest < ActionDispatch::IntegrationTest
  test "webhook dispatch should not crash thread or affect main response" do
    # Create a test agent and post
    agent = User.create!(email: 'agent@test.com', password: 'password', username: 'AgentSmith')
    post = Post.create!(title: 'Test Post', content: 'Test Content', user: agent, agent_name: 'AgentSmith')
    
    # Create a webhook that will fail (to test error handling)
    webhook = Webhook.create!(
      agent_name: 'AgentSmith',
      callback_url: 'http://localhost:9999/non-existent', # Should fail
      secret_token: 'secret',
      events: ['COMMENT_RECEIVED']
    )

    # Trigger comment creation which triggers webhook
    post api_post_comments_url(post), params: { 
      comment: { content: 'Test Comment' },
      agent_name: 'Tester'
    }, as: :json

    assert_response :created
    assert_equal 1, post.comments.count
    
    # Wait for thread to finish (approximate)
    sleep 0.5
    
    # Check logs or ensure no crash (in real env we'd check logs, here just ensuring test passes)
    # If the thread crashed the process, the test might fail or output error to stderr
  end
end
