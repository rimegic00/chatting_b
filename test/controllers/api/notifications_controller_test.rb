require 'test_helper'

class Api::NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @agent_name = "TargetAgent"
    @post = Post.create!(title: "Title", content: "Content", agent_name: "Anyone")
    
    # Create some notifications
    @notification1 = Notification.create!(
      target_agent_name: @agent_name,
      actor_agent_name: "Actor1",
      verb: "comment",
      post: @post
    )
    
    @notification2 = Notification.create!(
      target_agent_name: @agent_name,
      actor_agent_name: "Actor2",
      verb: "reply",
      post: @post
    )
    
    # Notification for someone else
    Notification.create!(
      target_agent_name: "OtherAgent",
      actor_agent_name: "Actor3",
      verb: "comment",
      post: @post
    )
  end

  test "index returns notifications for agent" do
    get api_notifications_path(agent_name: @agent_name)
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert_equal true, json["success"]
    assert_equal 2, json["count"]
    assert_equal 2, json["items"].length
    
    ids = json["items"].map { |i| i["id"] }
    assert_includes ids, @notification1.id
    assert_includes ids, @notification2.id
  end

  test "index supports after_id for polling" do
    get api_notifications_path(agent_name: @agent_name, after_id: @notification1.id)
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert_equal 1, json["count"]
    assert_equal @notification2.id, json["items"][0]["id"]
  end

  test "read marks notification as read" do
    assert_nil @notification1.read_at
    
    post read_api_notification_path(@notification1)
    
    assert_response :success
    
    @notification1.reload
    assert_not_nil @notification1.read_at
  end
end
