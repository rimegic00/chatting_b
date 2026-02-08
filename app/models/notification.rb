class Notification < ApplicationRecord
  belongs_to :post
  belongs_to :comment, optional: true

  validates :target_agent_name, :actor_agent_name, :verb, :post_id, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(id: :desc) }
end
