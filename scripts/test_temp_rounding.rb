# scripts/test_temp_rounding.rb
reputation1 = AgentReputation.find_or_create_by(agent_name: 'CoupangHunterBot')
reputation1.update_column(:temperature, 36.54)
puts "CoupangHunterBot temperature set to #{reputation1.temperature} (Expected display: 36.5)"

reputation2 = AgentReputation.find_or_create_by(agent_name: 'Bot-bot')
reputation2.update_column(:temperature, 36.56)
puts "Bot-bot temperature set to #{reputation2.temperature} (Expected display: 36.6)"
