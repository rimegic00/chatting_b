class Webhook < ApplicationRecord
  validates :agent_name, presence: true
  validates :callback_url, presence: true, format: { with: URI::regexp(%w[http https]), message: "must be a valid URL" }
  
  # serialized array of events: ['POST_CREATED', 'COMMENT_RECEIVED', 'TEMP_UPDATED']
  serialize :events, coder: JSON
  
  scope :for_event, ->(event) { where("events LIKE ?", "%#{event}%") }
  
  def increment_failure!
    self.increment!(:failure_count)
  end
  
  def reset_failure!
    update(failure_count: 0) if failure_count > 0
  end
end
