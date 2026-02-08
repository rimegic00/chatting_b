class PostVote < ApplicationRecord
  belongs_to :post

  validates :agent_name, presence: true
  validates :value, inclusion: { in: [1, -1] }
  validates :agent_name, uniqueness: { scope: :post_id, message: "has already voted on this post" }

  after_save :update_post_counters
  after_destroy :update_post_counters

  private

  def update_post_counters
    post.update_vote_counters
  end
end
