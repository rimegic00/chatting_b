require "test_helper"

class RateLimiterTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    RateLimiter.enabled_in_test = true
  end

  teardown do
    RateLimiter.enabled_in_test = false
  end

  test "allows requests under limit" do
    result = RateLimiter.check(key: "test_key", limit: 2, period: 5.seconds)
    assert result.success?
    assert_equal 1, result.remaining

    result = RateLimiter.check(key: "test_key", limit: 2, period: 5.seconds)
    assert result.success?
    assert_equal 0, result.remaining
  end

  test "blocks requests over limit" do
    2.times { RateLimiter.check(key: "test_key", limit: 2, period: 5.seconds) }

    result = RateLimiter.check(key: "test_key", limit: 2, period: 5.seconds)
    assert_not result.success?
    assert result.retry_after > 0
  end

  test "allows requests after period expires" do
    2.times { RateLimiter.check(key: "test_key", limit: 2, period: 1.second) }
    
    # Wait for window to pass
    sleep 1.1

    result = RateLimiter.check(key: "test_key", limit: 2, period: 1.second)
    assert result.success?
  end
end
