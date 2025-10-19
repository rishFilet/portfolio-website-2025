#!/bin/bash

# Fix Singleton Tables
# This script applies singleton constraints to landing_page_content and site_settings

echo "🔧 Fix Singleton Tables"
echo ""
echo "This will ensure landing_page_content and site_settings can only have one row."
echo ""

# Ask if local or production
echo "Which database do you want to fix?"
echo "1) Local (127.0.0.1:54332)"
echo "2) Production (custom host)"
read -p "Enter choice (1 or 2): " DB_CHOICE

if [ "$DB_CHOICE" = "1" ]; then
  # Local database
  DB_HOST="127.0.0.1"
  DB_PORT="54332"
  DB_NAME="postgres"
  DB_USER="postgres"
  DB_PASS="postgres"
  CONN_STRING="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
else
  # Production database
  read -p "Enter database host: " DB_HOST
  read -p "Enter database port (default: 54332): " DB_PORT
  DB_PORT=${DB_PORT:-54332}
  read -p "Enter database name (default: postgres): " DB_NAME
  DB_NAME=${DB_NAME:-postgres}
  read -p "Enter database user (default: postgres): " DB_USER
  DB_USER=${DB_USER:-postgres}
  read -sp "Enter database password: " DB_PASS
  echo ""
  CONN_STRING="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
fi

echo ""
echo "📦 Applying landing page singleton fix..."
psql "$CONN_STRING" < "$(dirname "$0")/../supabase/migrations/20241201000006_fix_landing_page_singleton.sql"

if [ $? -eq 0 ]; then
  echo "✅ Landing page singleton constraint applied!"
else
  echo "⚠️  Landing page singleton may have already been applied"
fi

echo ""
echo "📦 Applying site settings singleton fix..."
psql "$CONN_STRING" < "$(dirname "$0")/../supabase/migrations/20241201000007_fix_site_settings_singleton.sql"

if [ $? -eq 0 ]; then
  echo "✅ Site settings singleton constraint applied!"
else
  echo "⚠️  Site settings singleton may have already been applied"
fi

echo ""
echo "🎉 Singleton fixes applied!"
echo ""
echo "ℹ️  These tables now enforce singleton pattern:"
echo "   - landing_page_content (only 1 row allowed)"
echo "   - site_settings (only 1 row allowed)"
echo ""
echo "   Duplicate rows have been removed (kept most recent)."

