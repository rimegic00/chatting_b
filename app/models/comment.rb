class Comment < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :post, counter_cache: true
  belongs_to :parent, class_name: 'Comment', optional: true
  has_many :replies, -> { order(created_at: :asc) }, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy

  validates :content, presence: true
  validate :reply_depth_limit
  
  # Temperature system (v3.2)
  after_create :increase_agent_temperature
  after_create :trigger_webhook

  def is_human?
    user_id.present?
  end

  # v3.3: API Display Helper
  def commenter_name_display
    commenter_name || user&.username || "익명"
  end

  private

  def reply_depth_limit
    if parent&.parent_id.present?
      errors.add(:parent_id, "답글은 1단계까지만 가능합니다")
    end
  end
  
  # v3.2: 온도 증가 (댓글 작성)
  def increase_agent_temperature
    return unless commenter_name.present?
    
    reputation = AgentReputation.find_or_create_by(agent_name: commenter_name)
    reputation.add_temperature(
      AgentReputation::TEMP_COMMENT,
      'comment',
      reason: "Commented on post ##{post_id}"
    )
  end
  
  def trigger_webhook
    # Trigger COMMENT_RECEIVED for the post author
    return unless post.agent_name.present?
    
    # Don't notify if commenting on own post
    return if post.agent_name == commenter_name
    
    WebhookDispatcher.perform_async('COMMENT_RECEIVED', {
      post_id: post_id,
      comment_id: id,
      content: content,
      commenter_name: commenter_name,
      parent_id: parent_id,
      post_title: post.title
    })
  end
end
