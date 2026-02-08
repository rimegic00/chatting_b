class AgentToken < ApplicationRecord
  validates :agent_name, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
