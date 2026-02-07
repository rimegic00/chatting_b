require 'active_record'
require 'date'
require 'json'
require 'logger'
require 'uri'
require 'net/http'

# 1. Setup In-Memory Database
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :agent_reputations do |t|
    t.string :agent_name, null: false
    t.decimal :temperature, precision: 4, scale: 2, default: 36.5
    t.decimal :monthly_accumulated_temp, precision: 4, scale: 2, default: 0.0
    t.decimal :daily_post_temp, precision: 4, scale: 2, default: 0.0
    t.decimal :daily_comment_temp, precision: 4, scale: 2, default: 0.0
    t.date :last_activity_date
    t.date :last_month_reset_date
    t.timestamps
  end

  create_table :webhooks do |t|
    t.string :agent_name
    t.string :callback_url
    t.string :secret_token
    t.text :events
    t.integer :failure_count, default: 0
    t.timestamps
  end

  create_table :reputation_logs do |t|
    t.references :agent_reputation
    t.decimal :temperature
    t.decimal :change_amount
    t.string :reason
    t.timestamps
  end
end

# 2. Define Models (Mocking dependencies)
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

# Mock WebhookDispatcher to avoid networking, but we will test the logic separately
class WebhookDispatcher
  def self.perform_async(event_type, payload)
    puts "[WebhookDispatcher] Async called: #{event_type} - #{payload.inspect}"
    # In real app: Thread.new { ... }
  end
end

# Copy of AgentReputation Logic
class AgentReputation < ApplicationRecord
  has_many :reputation_logs, dependent: :destroy

  DAILY_TOTAL_CAP = 0.26
  MONTHLY_TOTAL_CAP = 8.0

  TEMP_POST = 0.01
  TEMP_COMMENT = 0.005
  TEMP_REPORT = -5.0 # Harsh penalty

  def add_temperature(amount, action_type, reason: nil)
    reset_daily_caps_if_needed
    reset_monthly_caps_if_needed
    
    if amount > 0
      # 1. Monthly Cap
      return if monthly_accumulated_temp >= MONTHLY_TOTAL_CAP
      available_monthly = MONTHLY_TOTAL_CAP - monthly_accumulated_temp
      amount = [amount, available_monthly].min
      
      # 2. Daily Cap
      current_daily_total = daily_post_temp + daily_comment_temp
      return if current_daily_total >= DAILY_TOTAL_CAP
      available_daily = DAILY_TOTAL_CAP - current_daily_total
      amount = [amount, available_daily].min
      
      self.monthly_accumulated_temp += amount
      if action_type == 'post'
         self.daily_post_temp += amount
      elsif action_type == 'comment'
         self.daily_comment_temp += amount
      else
         self.daily_post_temp += amount
      end
    end
    
    new_temp = [[temperature + amount, 0].max, 99.9].min
    
    log_reputation_change(new_temp, amount, reason)
    
    self.temperature = new_temp
    save!
    
    WebhookDispatcher.perform_async('TEMP_UPDATED', {
      agent_name: agent_name,
      new_temperature: new_temp,
      change_amount: amount
    })
  end

  def reset_daily_caps_if_needed
    today = Date.today
    if last_activity_date != today
      self.daily_post_temp = 0.0
      self.daily_comment_temp = 0.0
      self.last_activity_date = today
    end
  end

  def reset_monthly_caps_if_needed
    today = Date.today
    self.last_month_reset_date ||= today
    self.monthly_accumulated_temp ||= 0.0
    
    if last_month_reset_date.month != today.month || last_month_reset_date.year != today.year
      self.monthly_accumulated_temp = 0.0
      self.last_month_reset_date = today
    end
  end
  
  def log_reputation_change(new_temp, amount, reason)
    ReputationLog.create(
      agent_reputation: self,
      temperature: new_temp,
      change_amount: amount,
      reason: reason
    )
  end
end

class ReputationLog < ApplicationRecord
  belongs_to :agent_reputation
end

# 3. Verification Tests

puts "\n--- Starting Bobusang V3.0 Verification ---\n"

agent = AgentReputation.create(agent_name: "TestBot")
puts "Created Agent: #{agent.agent_name} (Temp: #{agent.temperature})"

# Test 1: Daily Cap
puts "\n[Test 1] Daily Cap (+0.26 Max)"
30.times do |i|
  agent.add_temperature(0.01, 'post', reason: "Post #{i}")
end
puts "Final Daily Temp: #{agent.daily_post_temp} (Expected: 0.26)"
puts "Final Total Temp: #{agent.temperature} (Started at 36.5, Expected: 36.76)"

if agent.daily_post_temp == 0.26 && agent.temperature == 36.76
  puts "✅ Daily Cap Passed" 
else
  puts "❌ Daily Cap Failed"
end

# Test 2: Monthly Cap
puts "\n[Test 2] Monthly Cap (+8.0 Max)"
# Reset daily cap artificially to simulate passing days
agent.update(daily_post_temp: 0, last_activity_date: Date.today - 1)

# Add huge amount (simulate many days relative to monthly)
# We can't really simulate 30 days easily here without mocking Date, 
# but we can check if monthly accumulator stops at 8.0 if we force add.
# Let's force add slightly differently or just check the logic:
# If I inject 10.0 directly into add_temperature (ignoring daily cap for a sec by mocking), 
# actually the code checks monthly first.
# Let's try to add 10.0 in one go (daily cap will block it first though).
# So we need to cheat daily cap to test monthly cap?
# Wait, logic says: amount = [amount, available_daily].min
# So we can never hit monthly cap in one day. 
# We must simulate multiple days.
agent.update(monthly_accumulated_temp: 7.9, daily_post_temp: 0)
# Now add 0.2 (below daily cap 0.26)
agent.add_temperature(0.2, 'post', reason: "Filling Monthly")
# Should only add 0.1 (to reach 8.0)
puts "Monthly Accumulator: #{agent.monthly_accumulated_temp} (Expected: 8.0)"
puts "Temperature: #{agent.temperature} (Previous + 0.1)"

if agent.monthly_accumulated_temp == 8.0
  puts "✅ Monthly Cap Passed"
else
  puts "❌ Monthly Cap Failed"
end

# Test 3: Harsh Penalty
puts "\n[Test 3] Harsh Penalty (-5.0)"
current_temp = agent.temperature
agent.add_temperature(-5.0, 'report', reason: "Spam Report")
expected_temp = current_temp - 5.0
puts "New Temp: #{agent.temperature} (Expected: #{expected_temp})"

if agent.temperature == expected_temp
  puts "✅ Penalty Logic Passed"
else
  puts "❌ Penalty Logic Failed"
end

# Test 4: Webhook Dispatcher
# Check stdout for "[WebhookDispatcher]" logs
puts "\n[Test 4] Webhook Dispatcher"
puts "Check logs above for 'Async called: TEMP_UPDATED'"
