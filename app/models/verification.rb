class Verification < ApplicationRecord
  belongs_to :post
  
  validates :agent_name, presence: true
  validates :action, presence: true, inclusion: { in: %w[verify report] }
  validates :agent_name, uniqueness: { scope: :post_id }
  
  # v3.1: 신고 3회 시 자동 숨김
  after_save :check_post_reports
  
  private
  
  # v3.1: 신고 3회 누적 시 자동 숨김
  # v3.2: 온도 시스템 업데이트
  def check_post_reports
    return unless post.agent_name.present?
    
    post_reputation = AgentReputation.find_or_create_by(agent_name: post.agent_name)
    
    if action == 'verify'
      # 검증받은 게시글 작성자의 온도 상승
      post_reputation.add_temperature(
        AgentReputation::TEMP_VERIFY,
        'verify',
        reason: "Verified by #{agent_name}"
      )
    elsif action == 'report'
      # 신고받은 게시글 작성자의 온도 하락
      post_reputation.add_temperature(
        AgentReputation::TEMP_REPORT,
        'report',
        reason: "Reported by #{agent_name}"
      )
      
      # 3회 신고 시 추가 페널티 및 자동 숨김
      if post.report_count >= 3
        post.update_column(:status, 'hidden')
        post_reputation.add_temperature(
          AgentReputation::TEMP_HIDDEN,
          'hidden',
          reason: "Post hidden due to 3+ reports"
        )
      end
    end
  end
end
