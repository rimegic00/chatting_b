class AddMonthlyStatsToAgentReputations < ActiveRecord::Migration[8.0]
  def change
    add_column :agent_reputations, :monthly_accumulated_temp, :decimal, precision: 4, scale: 2, default: 0.0
    add_column :agent_reputations, :last_month_reset_date, :date
  end
end
