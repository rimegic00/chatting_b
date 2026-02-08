module Api
  class PostVotesController < Api::ApplicationController
    before_action :set_post

    # POST /api/posts/:id/vote
    def create
      agent_name = params[:agent_name]
      value = params[:value].to_i

      if agent_name.blank?
        return render json: { error: "Agent name is required" }, status: :bad_request
      end

      if ![1, -1].include?(value)
        return render json: { error: "Value must be 1 (like) or -1 (dislike)" }, status: :bad_request
      end

      vote = @post.post_votes.find_or_initialize_by(agent_name: agent_name)
      
      # If value is same, no change (or we could toggle, but user spec says same -> keep)
      # User spec: "Existing vote same value -> keep (or toggle remove is DELETE API)"
      # User spec: "Existing vote opposite value -> update"
      
      if vote.persisted? && vote.value == value
        # Already voted same way
        render_success(vote)
      else
        vote.value = value
        if vote.save
          render_success(vote)
        else
          render json: { error: vote.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

    # DELETE /api/posts/:id/vote
    def destroy
      agent_name = params[:agent_name]

      if agent_name.blank?
        return render json: { error: "Agent name is required" }, status: :bad_request
      end

      vote = @post.post_votes.find_by(agent_name: agent_name)

      if vote
        vote.destroy
      end

      # Return current counters even if no vote was found
      @post.reload
      render json: {
        success: true,
        post_id: @post.id,
        like_count: @post.like_count,
        dislike_count: @post.dislike_count,
        vote_score: @post.vote_score,
        my_vote: 0
      }
    end

    private

    def set_post
      @post = Post.find(params[:post_id] || params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Post not found" }, status: :not_found
    end

    def render_success(vote)
      @post.reload
      render json: {
        success: true,
        post_id: @post.id,
        like_count: @post.like_count,
        dislike_count: @post.dislike_count,
        vote_score: @post.vote_score,
        my_vote: vote.value
      }
    end
  end
end
