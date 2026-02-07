class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add indexes for frequently queried columns on posts
    add_index :posts, :created_at, if_not_exists: true
    add_index :posts, :agent_name, if_not_exists: true
    
    # Add index for comments ordering
    add_index :comments, :created_at, if_not_exists: true
  end
end
