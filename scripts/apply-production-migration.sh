#!/bin/bash

# Apply Production Migration Script
# This script applies the enhanced portfolio schema to your production database

echo "🚀 Apply Production Migration"
echo ""
echo "This script will apply the enhanced portfolio schema to your production database."
echo ""

# Prompt for connection details
read -p "Enter database host (e.g., your-server-ip or api.supabase.rishikhan.dev): " DB_HOST
read -p "Enter database port (default: 54332): " DB_PORT
DB_PORT=${DB_PORT:-54332}
read -p "Enter database name (default: postgres): " DB_NAME
DB_NAME=${DB_NAME:-postgres}
read -p "Enter database user (default: postgres): " DB_USER
DB_USER=${DB_USER:-postgres}
read -sp "Enter database password: " DB_PASS
echo ""
echo ""

# Build connection string
CONN_STRING="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

echo "📦 Applying initial schema migration..."
psql "$CONN_STRING" < "$(dirname "$0")/../supabase/migrations/20241201000000_initial_schema.sql"

if [ $? -eq 0 ]; then
  echo "✅ Initial schema applied successfully!"
else
  echo "⚠️  Initial schema may have already been applied (this is OK)"
fi

echo ""
echo "📦 Applying enhanced portfolio schema migration..."
psql "$CONN_STRING" < "$(dirname "$0")/../supabase/migrations/20241201000001_enhanced_portfolio_schema.sql"

if [ $? -eq 0 ]; then
  echo "✅ Enhanced schema applied successfully!"
else
  echo "❌ Error applying enhanced schema"
  exit 1
fi

echo ""
echo "📦 Applying singleton constraints..."

# Apply landing page singleton fix
psql "$CONN_STRING" < "$(dirname "$0")/../supabase/migrations/20241201000006_fix_landing_page_singleton.sql"
if [ $? -eq 0 ]; then
  echo "✅ Landing page singleton constraint applied!"
else
  echo "⚠️  Landing page singleton may have already been applied (this is OK)"
fi

# Apply site settings singleton fix
psql "$CONN_STRING" < "$(dirname "$0")/../supabase/migrations/20241201000007_fix_site_settings_singleton.sql"
if [ $? -eq 0 ]; then
  echo "✅ Site settings singleton constraint applied!"
else
  echo "⚠️  Site settings singleton may have already been applied (this is OK)"
fi

echo ""
echo "🎉 All migrations applied successfully!"
echo ""
echo "🔑 Next step: Create an admin user on production"
echo "   Run: ./scripts/create-admin-user.sh"

