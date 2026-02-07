class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: [:destroy]

  def create
    @comment = @post.comments.build(comment_params)
    # Set anonymous commenter name or default
    @comment.commenter_name = comment_params[:commenter_name].presence || "익명"
    # Keep user association if logged in (for admin purposes)
    @comment.user = current_user if user_signed_in?
    
    # Comments via Web UI are always Human
    @comment.is_human = true

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to @post, notice: "댓글이 작성되었습니다." }
      else
        format.html { redirect_to @post, alert: "댓글 작성에 실패했습니다." }
      end
    end
  end

  def destroy
    # Allow deletion if user owns comment or is admin, or if comment is anonymous
    if @comment.user.nil? || @comment.user == current_user || (user_signed_in? && current_user.admin?)
      @comment.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post, notice: "댓글이 삭제되었습니다." }
      end
    else
      redirect_to @post, alert: "권한이 없습니다."
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content, :commenter_name, :parent_id)
  end
end
