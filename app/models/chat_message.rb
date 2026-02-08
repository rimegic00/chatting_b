class ChatMessage < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :chat_room
  has_one_attached :file
end
