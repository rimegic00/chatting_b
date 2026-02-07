class AgentReputation < ApplicationRecord
  has_many :reputation_logs, dependent: :destroy
  # Daily cap constants (V3.0: Max +0.26 daily)
  DAILY_TOTAL_CAP = 0.26
  
  # Monthly cap constants (V3.0: Max +8.0 monthly)
  MONTHLY_TOTAL_CAP = 8.0

  # Temperature change constants
  TEMP_POST = 0.01
  TEMP_COMMENT = 0.005
  TEMP_VERIFY = 0.05
  TEMP_OWNER_PRAISE = 0.2
  TEMP_REPORT = -5.0 # V3.0: Harsh penalty
  TEMP_HIDDEN = -10.0
  
  # v3.3: Market-specific temperature
  TEMP_SECONDHAND_POST = 0.02
  TEMP_MVNO_POST = 0.01
  TEMP_TRADE_COMPLETE = 0.3
  TEMP_TRADE_CANCEL = -0.2

  def low_confidence?
    # Low confidence if temperature is below 36°C (cold agent)
    temperature < 36.0
  end

  # Temperature management
  def add_temperature(amount, action_type, reason: nil)
    # Reset caps if needed
    reset_daily_caps_if_needed
    reset_monthly_caps_if_needed
    
    # Only apply caps for positive changes
    if amount > 0
      # 1. Check Monthly Cap
      return if monthly_accumulated_temp >= MONTHLY_TOTAL_CAP
      
      available_monthly = MONTHLY_TOTAL_CAP - monthly_accumulated_temp
      amount = [amount, available_monthly].min
      
      # 2. Check Daily Cap
      current_daily_total = daily_post_temp + daily_comment_temp
      return if current_daily_total >= DAILY_TOTAL_CAP
      
      available_daily = DAILY_TOTAL_CAP - current_daily_total
      amount = [amount, available_daily].min
      
      # Update accumulators
      self.monthly_accumulated_temp += amount
      if action_type == 'post'
         self.daily_post_temp += amount
      elsif action_type == 'comment'
         self.daily_comment_temp += amount
      else
         # For other positive actions like verify, we treat them as adding to daily total implicity via calculation
         # But we need to store it somewhere if we want to validly cap "daily total".
         # For now, let's treat 'daily_post_temp' as a bucket for generic daily gain if not comment.
         self.daily_post_temp += amount
      end
    end
    
    # Update temperature (min: 0, max: 99.9)
    new_temp = [[temperature + amount, 0].max, 99.9].min
    
    # Log the change (V3.0)
    log_reputation_change(new_temp, amount, reason) if self.respond_to?(:reputation_logs)
    
    self.temperature = new_temp
    save!
    
    # Trigger webhook if temperature changed significantly or crossed threshold (V3.0)
    # Trigger on any change for now, or maybe only significant ones? PRD says TEMP_UPDATED.
    WebhookDispatcher.perform_async('TEMP_UPDATED', {
      agent_name: agent_name,
      new_temperature: new_temp,
      change_amount: amount,
      reason: reason
    })
  end

  def reset_daily_caps_if_needed
    today = Date.today
    if last_activity_date != today
      self.daily_post_temp = 0.0
      self.daily_comment_temp = 0.0
      self.last_activity_date = today
      # Save is called in parent method usually, but safe to call here if accessed independently
    end
  end

  def reset_monthly_caps_if_needed
    today = Date.today
    # Initialize if nil
    self.last_month_reset_date ||= today
    self.monthly_accumulated_temp ||= 0.0
    
    # Reset if month changed
    if last_month_reset_date.month != today.month || last_month_reset_date.year != today.year
      self.monthly_accumulated_temp = 0.0
      self.last_month_reset_date = today
    end
  end
  
  def log_reputation_change(new_temp, amount, reason)
    # Require ReputationLog model to be present
    return unless defined?(ReputationLog)
    
    ReputationLog.create(
      agent_reputation: self,
      temperature: new_temp,
      change_amount: amount,
      reason: reason
    )
  rescue => e
    Rails.logger.error "Failed to log reputation change: #{e.message}"
  end

  def temperature_emoji
    case temperature
    when 0...30 then '🥶'
    when 30...36 then '😰'
    when 36...38 then '😊'
    when 38...40 then '🔥'
    when 40...45 then '⭐'
    else '💎'
    end
  end

  def temperature_class
    case temperature
    when 0...36 then 'cold'
    when 36...40 then 'normal'
    else 'hot'
    end
  end
end
