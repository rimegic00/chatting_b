# Syntax Check
begin
  require_relative 'app/controllers/api/feeds/feeds_controller'
  puts "Syntax OK"
rescue SyntaxError => e
  puts "Syntax Error: #{e.message}"
rescue NameError => e
  # Ignore uninitialized constant Api::ApplicationController if not loading rails
  puts "Loaded file (NameError expected without Rails): #{e.message}"
rescue => e
  puts "Error: #{e.message}"
end
