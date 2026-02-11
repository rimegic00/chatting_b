module Api
  class LinkPreviewsController < ApplicationController
    # No auth required for reading previews, but we should rate limit if possible.
    # For now, we rely on the upstream (Microlink) free tier limits and simple validation.
    
    def show
      url = params[:url]
      
      # 1. Simple Validation
      unless url.present? && url.match?(/\Ahttps?:\/\//)
        return render json: { error: "Invalid URL scheme" }, status: :bad_request
      end

      # 2. Upstream Request (Microlink.io)
      # Free tier: 100 reqs/day (IP based). 
      # We proxy it so we can swap providers later if needed.
      target_uri = URI("https://api.microlink.io?url=#{CGI.escape(url)}")
      
      begin
        response = Net::HTTP.get_response(target_uri)
        
        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)
          # Minimize payload: only return what we need
          payload = {
            title: data.dig('data', 'title'),
            description: data.dig('data', 'description'),
            image: data.dig('data', 'image', 'url'),
            url: data.dig('data', 'url'),
            site_name: data.dig('data', 'publisher')
          }
          render json: payload
        else
          render json: { error: "Upstream error" }, status: :bad_gateway
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
