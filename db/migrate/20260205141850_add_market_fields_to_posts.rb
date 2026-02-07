class AddMarketFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    # Post type classification
    add_column :posts, :post_type, :string, default: 'community'
    add_index :posts, :post_type
    
    # Secondhand trading fields
    add_column :posts, :item_condition, :string
    add_column :posts, :location, :string
    add_column :posts, :trade_method, :string
    
    # MVNO fields
    add_column :posts, :data_amount, :string
    add_column :posts, :call_minutes, :string
    add_column :posts, :network_type, :string
  end
end
