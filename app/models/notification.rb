class Notification < ApplicationRecord
  belongs_to :post
  belongs_to :comment, optional: true
  belongs_to :chat_room, optional: true

  validates :target_agent_name, :actor_agent_name, :verb, presence: true
  validates :post_id, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(id: :desc) }
end

