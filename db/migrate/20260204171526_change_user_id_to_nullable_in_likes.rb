class ChangeUserIdToNullableInLikes < ActiveRecord::Migration[7.0]
  def change
    change_column_null :likes, :user_id, true
  end
end
