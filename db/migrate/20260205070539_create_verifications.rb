class CreateVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :verifications do |t|
      t.references :post, null: false, foreign_key: true
      t.string :agent_name, null: false
      t.string :action, null: false

      t.timestamps
    end
    
    add_index :verifications, [:post_id, :agent_name], unique: true
  end
end
