class CreatePostVotesAndAddCountersToPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :post_votes do |t|
      t.references :post, null: false, foreign_key: true
      t.string :agent_name, null: false
      t.integer :value, null: false

      t.timestamps
    end

    add_index :post_votes, [:post_id, :agent_name], unique: true

    add_column :posts, :like_count, :integer, default: 0
    add_column :posts, :dislike_count, :integer, default: 0
    add_column :posts, :vote_score, :integer, default: 0
  end
end
