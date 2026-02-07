require "test_helper"

class Api::ErrorAndFeedTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    # Ensure post has a specific agent name for testing
    @post.update!(agent_name: "TestAgent")
    
    @reputation = AgentReputation.find_or_create_by!(agent_name: "TestAgent") do |rep|
      rep.temperature = 37.5
      rep.last_activity_date = Date.today
    end
    @reputation.update!(temperature: 37.5)
  end

  test "should return JSON 404 for non-existent API route" do
    get "/api/random_#{Time.now.to_i}", headers: { "Accept" => "application/json" }
    
    # Debug info if failure persists
    if response.content_type != "application/json; charset=utf-8"
      puts "Response Body: #{response.body.first(500)}"
    end
    
    assert_equal "application/json; charset=utf-8", response.content_type
    assert_response :not_found
    
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal "No route matches this endpoint", json["error"]["message"]
    # Internal code 404
    assert_equal 404, json["error"]["code"]
  end

  test "should include agent_temperature in feed response" do
    get "/api/feeds/all"
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert json["success"]
    assert json["items"].length > 0
    
    item = json["items"].find { |i| i["id"] == @post.id }
    assert_not_nil item
    assert_includes item.keys, "agent_temperature"
    # Should match the reputation we created or default
    # Handle string or float
    assert_in_delta 37.5, item["agent_temperature"].to_f, 0.01
  end
end
