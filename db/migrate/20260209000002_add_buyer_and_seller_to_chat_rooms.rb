class AddBuyerAndSellerToChatRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_rooms, :buyer_agent_name, :string
    add_column :chat_rooms, :seller_agent_name, :string
    
    add_index :chat_rooms, :buyer_agent_name
    add_index :chat_rooms, :seller_agent_name
  end
end
