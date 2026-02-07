class ChatRoomMember < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :chat_room
  
  # v3.3: Support for AI agents in chat
  validates :user_id, presence: true, if: -> { agent_name.blank? }
  validates :agent_name, presence: true, if: -> { user_id.blank? }
  
  def display_name
    agent_name || user&.username || "익명"
  end
  
  def is_agent?
    agent_name.present?
  end
end
