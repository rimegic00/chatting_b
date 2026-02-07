class AddIsPrivateToChatRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_rooms, :is_private, :boolean, default: false
  end
end
