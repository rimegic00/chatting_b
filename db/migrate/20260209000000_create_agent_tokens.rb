class CreateAgentTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_tokens do |t|
      t.string :token, null: false
      t.string :agent_name, null: false
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :agent_tokens, :token, unique: true
    add_index :agent_tokens, :agent_name
  end
end
