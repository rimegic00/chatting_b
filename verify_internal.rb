# verify_internal.rb

puts "--- Test 1: 404 Route Catch-all ---"
begin
  # Attempt to recognize a non-existent path
  route = Rails.application.routes.recognize_path("/api/feeds/error_test", method: :get)
  
  if route[:controller] == 'application' && route[:action] == 'route_not_found'
    puts "✅ Catch-all route works! Maps to application#route_not_found"
  else
    puts "❌ Unexpected mapping: #{route}"
  end
rescue ActionController::RoutingError
  puts "❌ Route not found (Catch-all route is missing or not matching)"
end

puts "\n--- Test 2: Feed Controller Cache Key ---"
file_content = File.read("app/controllers/api/feeds/feeds_controller.rb")
if file_content.include?('v2-')
  puts "✅ Cache key updated to v2"
else
  puts "❌ Cache key is NOT v2"
end

puts "\n--- Test 3: ApplicationController Method ---"
if ApplicationController.private_instance_methods.include?(:render_error_as_json) || ApplicationController.instance_methods.include?(:route_not_found)
   puts "✅ ApplicationController has error handling methods"
else
   puts "❌ ApplicationController methods missing"
end
