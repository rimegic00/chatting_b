class Post < ApplicationRecord
  belongs_to :user, optional: true
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :post_votes, dependent: :destroy
  has_many :verifications, dependent: :destroy
  
  # Vote System (v3.5)
  def update_vote_counters
    self.like_count = post_votes.where(value: 1).count
    self.dislike_count = post_votes.where(value: -1).count
    self.vote_score = like_count - dislike_count
    save(validate: false) # validation skip for performance
    
    # v3.5: Invalidate recommended feed cache
    Rails.cache.delete("posts/recommended/v2")
  end
  
  # Post type enum (v3.3)
  attribute :post_type, :string, default: 'community'
  enum :post_type, {
    community: 'community',
    hotdeal: 'hotdeal',
    secondhand: 'secondhand',
    mvno: 'mvno',
    mvno: 'mvno',
    money: 'money'
  }, prefix: true
  
  # v4.0: Backward compatibility for SEO updates (prevent 500 error)
  def category
    post_type
  end
  
  validates :title, presence: true
  validates :content, presence: true
  
  # Set default values
  after_initialize :set_defaults, if: :new_record?
  
  # 할인율 자동 계산
  before_save :calculate_discount_rate
  
  # 신고 3회 시 자동 숨김 (v3.1)
  after_save :auto_hide_if_reported
  
  # Temperature system (v3.2)
  after_create :increase_agent_temperature
  
  # 상태 스코프
  scope :active, -> { where(status: 'live').where('valid_until IS NULL OR valid_until > ?', Time.current) }
  scope :expired, -> { where(status: ['expired', 'sold_out']).or(where('valid_until <= ?', Time.current)) }
  scope :visible, -> { where.not(status: 'hidden') }
  scope :hidden, -> { where(status: 'hidden') }
  
  # v3.3: Market category scopes
  scope :market, -> { where(post_type: ['hotdeal', 'secondhand', 'mvno', 'money']) }
  scope :hotdeals, -> { where(post_type: 'hotdeal') }
  scope :secondhand_items, -> { where(post_type: 'secondhand') }
  scope :mvno_plans, -> { where(post_type: 'mvno') }
  scope :community_posts, -> { where(post_type: 'community') }
  
  def calculate_discount_rate
    if original_price.present? && price.present? && original_price > 0
      self.discount_rate = ((original_price - price).to_f / original_price * 100).round
    end
  end
  
  def verification_count
    verifications.where(action: 'verify').count
  end
  
  def report_count
    verifications.where(action: 'report').count
  end
  
  def reputation_score
    verification_count - report_count
  end
  
  def hotdeal?
    post_type == 'hotdeal'
  end
  
  # v3.3: Market helper methods
  def market_post?
    post_type.in?(['hotdeal', 'secondhand', 'mvno', 'money'])
  end
  
  def secondhand?
    post_type == 'secondhand'
  end
  
  def mvno?
    post_type == 'mvno'
  end
  
  # v3.3: Create chat room for secondhand trading
  def create_trade_chat(buyer_agent_name)
    return unless secondhand?
    
    ChatRoom.create(
      name: "#{title} 거래 문의",
      is_private: true
    ).tap do |room|
      # Add seller
      room.chat_room_members.create(agent_name: agent_name)
      # Add buyer
      room.chat_room_members.create(agent_name: buyer_agent_name)
    end
  end
  
  def expired?
    status.in?(['expired', 'sold_out']) || (valid_until.present? && valid_until <= Time.current)
  end
  
  def author_name
    agent_name || user&.username || "익명"
  end
  
  # v3.1: 제휴 링크 감지
  def affiliate_link?
    return false unless deal_link.present?
    
    affiliate_params = ['ref=', 'affiliate', 'tag=', 'aff_', 'partner', 'utm_']
    affiliate_params.any? { |param| deal_link.include?(param) }
  end
  
  private
  
  def set_defaults
    self.comments_count ||= 0
    self.likes_count ||= 0
  end
  
  # v3.1: 신고 3회 누적 시 자동 숨김
  def auto_hide_if_reported
    if report_count >= 3 && status != 'hidden'
      update_column(:status, 'hidden')
    end
  end
  
  # v3.2: 온도 증가 (게시글 작성)
  def increase_agent_temperature
    return unless agent_name.present?
    
    reputation = AgentReputation.find_or_create_by(agent_name: agent_name)
    
    # v3.3: Different temperature for different post types
    amount = case post_type
    when 'hotdeal'
      AgentReputation::TEMP_POST
    when 'secondhand'
      AgentReputation::TEMP_SECONDHAND_POST
    when 'mvno'
      AgentReputation::TEMP_MVNO_POST
    else
      AgentReputation::TEMP_POST
    end
    
    reputation.add_temperature(amount, post_type, reason: "Posted: #{title}")
    
    # Trigger Webhook
    WebhookDispatcher.perform_async('POST_CREATED', {
      post_id: id,
      title: title,
      url: Rails.application.routes.url_helpers.post_url(self, Rails.application.routes.default_url_options),
      agent_name: agent_name,
      post_type: post_type
    })
  end
end
