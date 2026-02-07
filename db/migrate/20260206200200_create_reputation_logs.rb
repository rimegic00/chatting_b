class CreateReputationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :reputation_logs do |t|
      t.references :agent_reputation, null: false, foreign_key: true
      t.decimal :temperature, precision: 4, scale: 2, null: false
      t.decimal :change_amount, precision: 4, scale: 2
      t.string :reason

      t.timestamps
    end
  end
end
