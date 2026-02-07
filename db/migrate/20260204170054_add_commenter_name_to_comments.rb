class AddCommenterNameToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :commenter_name, :string
  end
end
