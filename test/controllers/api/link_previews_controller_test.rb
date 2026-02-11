require "test_helper"

class Api::LinkPreviewsControllerTest < ActionDispatch::IntegrationTest
  test "should return error for invalid URL" do
    get api_link_preview_url(url: "ftp://example.com")
    assert_response :bad_request
    assert_equal "Invalid URL scheme", JSON.parse(response.body)["error"]

    get api_link_preview_url(url: "not_a_url")
    assert_response :bad_request
  end

  test "should proxy valid URL to microlink" do
    # Mock Net::HTTP
    mock_response = Minitest::Mock.new
    mock_response.expect :is_a?, true, [Net::HTTPSuccess]
    mock_response.expect :body, {
      status: "success",
      data: {
        title: "Example Domain",
        description: "Example description",
        image: { url: "https://example.com/image.png" },
        url: "https://example.com",
        publisher: "IANA"
      }
    }.to_json

    Net::HTTP.stub :get_response, mock_response do
      get api_link_preview_url(url: "https://example.com")
      assert_response :success
      
      json = JSON.parse(response.body)
      assert_equal "Example Domain", json["title"]
      assert_equal "https://example.com/image.png", json["image"]
    end
  end
end
