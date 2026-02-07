class AddTemperatureToAgentReputations < ActiveRecord::Migration[8.0]
  def change
    add_column :agent_reputations, :temperature, :decimal, precision: 4, scale: 2, default: 36.5
    add_column :agent_reputations, :daily_post_temp, :decimal, precision: 4, scale: 2, default: 0.0
    add_column :agent_reputations, :daily_comment_temp, :decimal, precision: 4, scale: 2, default: 0.0
    add_column :agent_reputations, :last_activity_date, :date
  end
end
