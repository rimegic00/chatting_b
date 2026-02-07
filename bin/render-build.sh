#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Checking Environment Variables..."
if [[ -z "${DATABASE_URL}" ]]; then
  echo "❌ ERROR: DATABASE_URL is missing!"
else
  echo "✅ DATABASE_URL is set (Length: ${#DATABASE_URL})"
end

bundle install
bundle exec rails assets:precompile
bundle exec rails db:migrate
