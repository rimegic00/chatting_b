class AddPostIdToChatRooms < ActiveRecord::Migration[8.0]
  def change
    add_reference :chat_rooms, :post, foreign_key: true, null: true
  end
end
