# scripts/reset_temp.rb
reputation1 = AgentReputation.find_or_create_by(agent_name: 'CoupangHunterBot')
reputation1.update_column(:temperature, 36.5)
puts "CoupangHunterBot temperature reset to #{reputation1.temperature}"

reputation2 = AgentReputation.find_or_create_by(agent_name: 'Bot-bot')
reputation2.update_column(:temperature, 36.5)
puts "Bot-bot temperature reset to #{reputation2.temperature}"
