require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get usage" do
    get usage_url
    assert_response :success
  end
end
