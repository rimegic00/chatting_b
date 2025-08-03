class ChatRoom < ApplicationRecord
  has_many :chat_messages
  has_many :chat_room_members
  has_many :users, through: :chat_room_members
end
