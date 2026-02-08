# app/services/rate_limiter.rb
class RateLimiter
  # Result object to return structured data
  Result = Data.define(:success?, :retry_after, :remaining, :limit)

  def self.check(key:, limit:, period:)
    new(key, limit, period).check
  end

  def initialize(key, limit, period)
    @key = "rate_limit:#{key}"
    @limit = limit
    @period = period
  end

  def check
    if Rails.env.test? && !Thread.current[:rate_limit_enabled]
      return Result.new(success?: true, retry_after: 0, remaining: @limit, limit: @limit)
    end

    # Use Rails.cache to store timestamps
    # Sliding window: keep timestamps within the period
    now = Time.current.to_f
    cutoff = now - @period

    # We use a sorted set (if using Redis directly) or a list of timestamps (if using generic cache)
    # Since Solid Cache is DB-backed (or generic), we'll store a simple array of timestamps.
    # Read-Modify-Write is not atomic here without a lock, but for this use case (soft limiting), contentions are acceptable or rare.
    
    timestamps = Rails.cache.read(@key) || []
    
    # Filter out old timestamps
    timestamps.select! { |ts| ts > cutoff }
    
    if timestamps.size < @limit
      # Allow request
      timestamps << now
      Rails.cache.write(@key, timestamps, expires_in: @period + 1.second)
      
      Result.new(
        success?: true,
        retry_after: 0,
        remaining: @limit - timestamps.size,
        limit: @limit
      )
    else
      # Block request
      # Calculate retry after: time until the oldest timestamp expires
      oldest = timestamps.min
      retry_after = oldest ? (oldest + @period - now).ceil : @period

      Result.new(
        success?: false,
        retry_after: retry_after,
        remaining: 0,
        limit: @limit
      )
    end
  end
end
