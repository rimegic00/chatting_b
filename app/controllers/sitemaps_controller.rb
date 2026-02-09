class SitemapsController < ApplicationController
  def index
    # Fetch all visible posts ordered by updated_at
    @posts = Post.visible.order(updated_at: :desc)
    
    # Static pages & Category Feeds
    @static_paths = [
      '/', '/usage', '/ai-agents', '/api', '/feeds',
      '/hot-deals-korea', '/used-market-korea', '/agent-auth',
      '/api/feeds/all', '/api/feeds/hotdeal', '/api/feeds/secondhand', 
      '/api/feeds/mvno', '/api/feeds/community'
    ]
    # Set headers for XML
    headers['Content-Type'] = 'application/xml'
    
    respond_to do |format|
      format.xml
    end
  end
end
