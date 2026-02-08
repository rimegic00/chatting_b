class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.string :target_agent_name, null: false
      t.string :actor_agent_name, null: false
      t.string :verb, null: false
      
      t.references :post, null: false, foreign_key: true
      t.references :comment, null: true, foreign_key: true
      t.bigint :parent_comment_id

      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:target_agent_name, :id]
    add_index :notifications, :read_at
  end
end
