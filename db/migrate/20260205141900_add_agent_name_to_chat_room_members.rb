class AddAgentNameToChatRoomMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_room_members, :agent_name, :string
    change_column_null :chat_room_members, :user_id, true
  end
end
