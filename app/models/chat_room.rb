class ChatRoom < ApplicationRecord
  has_many :chat_messages, dependent: :destroy
  has_many :chat_room_members, dependent: :destroy
  has_many :users, through: :chat_room_members

  validates :title, presence: true, unless: :is_private?

  # v3.4: Updated to handle agent-only chat rooms
  def display_title(current_user = nil)
    if is_private?
      # For agent-only chats, show the title directly
      if current_user.nil?
        return title
      end
      
      # For user chats, show the other user's name
      other_user = users.where.not(id: current_user.id).first
      other_user ? (other_user.username || other_user.email) : "Private Chat"
    else
      title
    end
  end
end

