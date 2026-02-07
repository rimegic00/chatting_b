require 'net/http'

class WebhookDispatcher
  include Rails.application.routes.url_helpers
  
  MAX_RETRIES = 3
  
  def self.perform_async(event_type, payload)
    # flexible execution: ideally use Sidekiq/ActiveJob. For now Thread/Async or direct call.
    # We will just run it in a new thread to avoid blocking response.
    Thread.new do
      Rails.application.executor.wrap do
        new.perform(event_type, payload)
      rescue => e
        Rails.logger.error "[WebhookDispatcher] Thread Error: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end

  def perform(event_type, payload)
    # Find interested webhooks
    # Note: Using simple LIKE query for serialized array JSON. 
    # Better to use JSONB in Postgres, but this works for text/string.
    webhooks = Webhook.all.select { |wh| wh.events&.include?(event_type) }
    
    webhooks.each do |webhook|
      dispatch(webhook, event_type, payload)
    end
  end

  private

  def dispatch(webhook, event_type, payload)
    uri = URI(webhook.callback_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 2
    http.read_timeout = 2
    
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = {
      event: event_type,
      timestamp: Time.current.iso8601,
      payload: payload
    }.to_json
    
    # Add signature if token exists
    if webhook.secret_token.present?
      signature = OpenSSL::HMAC.hexdigest('SHA256', webhook.secret_token, request.body)
      request['X-Bobusang-Signature'] = signature
    end

    begin
      response = http.request(request)
      if response.kind_of?(Net::HTTPSuccess)
        webhook.reset_failure!
        Rails.logger.info "[Webhook] Sent #{event_type} to #{webhook.agent_name} (Success)"
      else
        handle_failure(webhook, "HTTP #{response.code}")
      end
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout, Net::ReadTimeout => e
      handle_failure(webhook, "Network Error: #{e.message}")
    rescue => e
      handle_failure(webhook, e.message)
    end
  end
  
  def handle_failure(webhook, error_msg)
    Rails.logger.error "[Webhook] Failed to send to #{webhook.agent_name}: #{error_msg}"
    webhook.increment_failure!
    # Reuse simple retry logic or just log for V3.0
  end
end
