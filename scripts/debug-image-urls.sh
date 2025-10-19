#!/bin/bash

# Debug Image URLs
# This script checks what URLs are stored in the database

echo "🔍 Debugging Image URLs in Database"
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
echo "📋 Checking stored image URLs..."
echo ""

psql "$CONN_STRING" << 'EOF'
\echo '=== Theme Logos ==='
SELECT 
  unique_name as theme,
  logo_url
FROM themes
WHERE logo_url IS NOT NULL AND logo_url != ''
ORDER BY unique_name;

\echo ''
\echo '=== Theme Hero Images ==='
SELECT 
  unique_name as theme,
  hero_image_url
FROM themes
WHERE hero_image_url IS NOT NULL AND hero_image_url != ''
ORDER BY unique_name;

\echo ''
\echo '=== Site Settings (Favicon) ==='
SELECT 
  favicon_url
FROM site_settings
WHERE favicon_url IS NOT NULL AND favicon_url != '';

\echo ''
\echo '=== Blog Post Images ==='
SELECT 
  bpi.image_name,
  bpi.image_url
FROM blog_post_images bpi
LIMIT 5;

\echo ''
\echo '=== Project Post Images ==='
SELECT 
  ppi.image_name,
  ppi.image_url
FROM project_post_images ppi
LIMIT 5;

EOF

echo ""
echo "✅ Check complete!"
echo ""
echo "📌 Check if URLs contain:"
echo "   - Correct domain (api.supabase.rishikhan.dev)"
echo "   - Correct port (54331)"
echo "   - Pattern: /storage/v1/object/public/{bucket}/{filename}"

