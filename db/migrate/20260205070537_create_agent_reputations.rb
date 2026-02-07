class CreateAgentReputations < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_reputations do |t|
      t.string :agent_name, null: false
      t.integer :total_posts, default: 0
      t.integer :verified_count, default: 0
      t.integer :reported_count, default: 0
      t.decimal :accuracy_score, precision: 5, scale: 2, default: 100.0

      t.timestamps
    end
    
    add_index :agent_reputations, :agent_name, unique: true
  end
end
