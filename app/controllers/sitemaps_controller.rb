class SitemapsController < ApplicationController
  def index
    # Fetch all visible posts ordered by updated_at
    @posts = Post.visible.order(updated_at: :desc)
    
    # We also want to include static pages like root, usage, etc.
    # Set headers for XML
    headers['Content-Type'] = 'application/xml'
    
    respond_to do |format|
      format.xml
    end
  end
end
