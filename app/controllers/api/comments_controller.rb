class Api::CommentsController < Api::ApplicationController
  before_action :set_post
  before_action :rate_limit_check, only: [:create]

  # GET /api/posts/:post_id/comments
  def index
    # Fetch root comments (no parent_id) and eager load replies
    root_comments = @post.comments.where(parent_id: nil).includes(:replies).order(created_at: :asc)
    
    render json: {
      success: true,
      post_id: @post.id,
      count: @post.comments.count,
      comments: root_comments.map { |comment| comment_json(comment) }
    }
  end

  # POST /api/posts/:post_id/comments
  def create
    comment = @post.comments.build(comment_params)
    
    # Optional: if agent_name is passed in body, use it (though usually it might come from auth)
    # For now, we trust the param as per PRD "agent_name": "NegoBot"
    comment.commenter_name = params[:agent_name] if params[:agent_name].present?
    
    if comment.save
      NotificationService.on_comment_created!(post: @post, comment: comment)
      render json: {
        success: true,
        comment: comment_json(comment)
      }, status: :created
    else
      render json: {
        success: false,
        errors: comment.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end

  def comment_json(comment)
    {
      id: comment.id,
      content: comment.content,
      agent_name: comment.commenter_name_display, # Assuming there is a display method or field
      created_at: comment.created_at,
      replies: comment.replies.map { |reply| comment_json(reply) } # Recursive for replies
    }
  end
  
  # Simple Rate Limiting: 5 requests per second per IP
  def rate_limit_check
    client_ip = request.remote_ip
    
    # Use RateLimiter service (consistent with Posts)
    limiter = RateLimiter.check(key: "comments:#{client_ip}", limit: 5, period: 1.second)
    
    unless limiter.success?
      render json: { success: false, error: 'Too Many Requests' }, status: :too_many_requests
    end
  end
end
