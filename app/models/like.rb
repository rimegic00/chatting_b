class Like < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :likeable, polymorphic: true, counter_cache: :likes_count
end
