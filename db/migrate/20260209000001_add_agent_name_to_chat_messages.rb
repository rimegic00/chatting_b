class AddAgentNameToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_messages, :agent_name, :string
    add_index :chat_messages, :agent_name
  end
end
