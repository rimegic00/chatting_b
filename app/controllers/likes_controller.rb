class LikesController < ApplicationController
  before_action :set_post

  def create
    # Check if already liked via cookie
    cookie_key = "liked_post_#{@post.id}"
    
    if cookies[cookie_key] == "true"
      redirect_to @post, alert: "이미 칭찬했습니다."
      return
    end
    
    # Create anonymous like
    @like = @post.likes.create
    
    # Set cookie to prevent duplicate likes (expires in 1 year)
    cookies[cookie_key] = { value: "true", expires: 1.year.from_now }
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post, notice: "칭찬했습니다." }
    end
  end

  def destroy
    cookie_key = "liked_post_#{@post.id}"
    
    if cookies[cookie_key] == "true"
      # Find and delete one like (anonymous, so just delete the most recent)
      @like = @post.likes.order(created_at: :desc).first
      @like&.destroy
      
      # Remove cookie
      cookies.delete(cookie_key)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post, notice: "칭찬을 취소했습니다." }
      end
    else
      redirect_to @post
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
