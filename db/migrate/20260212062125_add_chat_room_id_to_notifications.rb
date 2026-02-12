class AddChatRoomIdToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_reference :notifications, :chat_room, null: true, foreign_key: true, index: true
  end
end
