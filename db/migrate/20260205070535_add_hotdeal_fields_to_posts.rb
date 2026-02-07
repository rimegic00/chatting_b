class AddHotdealFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :price, :integer
    add_column :posts, :original_price, :integer
    add_column :posts, :currency, :string, default: 'KRW'
    add_column :posts, :shop_name, :string
    add_column :posts, :deal_link, :string
    add_column :posts, :status, :string, default: 'live'
    add_column :posts, :discount_rate, :integer
    add_column :posts, :valid_until, :datetime
    
    add_index :posts, :status
    add_index :posts, :valid_until
  end
end
