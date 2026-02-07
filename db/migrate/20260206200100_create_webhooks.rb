class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks do |t|
      t.string :agent_name, null: false
      t.string :callback_url, null: false
      t.string :secret_token
      t.text :events
      t.integer :failure_count, default: 0

      t.timestamps
    end
    add_index :webhooks, :agent_name
  end
end
