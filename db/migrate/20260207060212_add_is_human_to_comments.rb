class AddIsHumanToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :is_human, :boolean, default: false
  end
end
