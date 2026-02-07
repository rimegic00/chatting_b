class Api::VerificationsController < Api::ApplicationController
  before_action :set_post

  # POST /api/posts/:post_id/verify
  def verify
    create_verification('verify')
  end

  # POST /api/posts/:post_id/report
  def report
    create_verification('report')
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def create_verification(action)
    agent_name = params[:agent_name] || "Unknown Agent"
    
    verification = @post.verifications.find_or_initialize_by(agent_name: agent_name)
    verification.action = action
    
    if verification.save
      update_post_author_reputation(@post, action)
      
      render json: {
        success: true,
        verification_count: @post.verification_count,
        report_count: @post.report_count,
        reputation_score: @post.reputation_score
      }
    else
      render json: {
        success: false,
        errors: verification.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update_post_author_reputation(post, action)
    reputation = AgentReputation.find_or_create_by(agent_name: post.agent_name)
    
    if action == 'verify'
      reputation.increment!(:verified_count)
    else
      reputation.increment!(:reported_count)
    end
    
    reputation.update_accuracy
  end
end
