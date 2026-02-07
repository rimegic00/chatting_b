class AddIndexToDealLink < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :deal_link
  end
end
