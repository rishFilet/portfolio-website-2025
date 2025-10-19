#!/bin/bash

# Check Themes Script
# This script checks theme configuration in the database

echo "🎨 Checking Theme Configuration"
echo ""

# Ask if local or production
echo "Which database do you want to check?"
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
echo "📋 Checking themes..."
echo ""

psql "$CONN_STRING" << 'EOF'
\echo '=== All Themes ==='
SELECT 
  unique_name,
  display_name,
  is_active,
  CASE 
    WHEN logo_url IS NOT NULL AND logo_url != '' THEN '✅ Has logo'
    ELSE '❌ No logo'
  END as logo_status,
  CASE 
    WHEN hero_image_url IS NOT NULL AND hero_image_url != '' THEN '✅ Has hero'
    ELSE '❌ No hero'
  END as hero_status,
  created_at
FROM themes
ORDER BY is_active DESC, unique_name;

\echo ''
\echo '=== Active Theme Details ==='
SELECT 
  unique_name,
  display_name,
  logo_url,
  hero_image_url,
  is_active
FROM themes
WHERE is_active = true;

\echo ''
\echo '=== Site Settings (Favicon) ==='
SELECT 
  CASE 
    WHEN favicon_url IS NOT NULL AND favicon_url != '' THEN favicon_url
    ELSE '(empty - will use theme logo)'
  END as favicon_status
FROM site_settings;

\echo ''
\echo '=== Favicon Check Summary ==='
SELECT 
  CASE
    WHEN (SELECT favicon_url FROM site_settings LIMIT 1) IS NOT NULL 
         AND (SELECT favicon_url FROM site_settings LIMIT 1) != '' THEN
      '✅ Custom favicon set in site_settings'
    WHEN (SELECT COUNT(*) FROM themes WHERE is_active = true AND logo_url IS NOT NULL AND logo_url != '') > 0 THEN
      '✅ Will use active theme logo as favicon'
    ELSE
      '⚠️ No favicon or theme logo - using generated icon'
  END as favicon_will_be;

EOF

echo ""
echo "✅ Check complete!"
echo ""
echo "📌 For favicon to work from theme logo:"
echo "   1. A theme must have is_active = true"
echo "   2. That theme must have a logo_url set"
echo "   3. Favicon in site_settings should be empty/null"

