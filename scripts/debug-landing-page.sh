#!/bin/bash

# Debug Landing Page Content
# This script checks the landing_page_content table for issues

echo "🔍 Debugging Landing Page Content"
echo ""

# Prompt for connection details
read -p "Enter database host (e.g., api.supabase.rishikhan.dev or 127.0.0.1): " DB_HOST
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

echo "📋 Checking landing_page_content table..."
echo ""

psql "$CONN_STRING" << 'EOF'
-- Check how many rows exist
SELECT COUNT(*) as row_count FROM landing_page_content;

\echo ''
\echo 'All rows in landing_page_content:'
\echo ''

-- Show all rows
SELECT 
  id,
  header,
  description,
  sub_headers,
  created_at,
  updated_at
FROM landing_page_content
ORDER BY created_at DESC;

\echo ''
\echo 'Checking for singleton constraint...'
\echo ''

-- Check constraints
SELECT 
  conname as constraint_name,
  contype as constraint_type
FROM pg_constraint
WHERE conrelid = 'landing_page_content'::regclass;

EOF

echo ""
echo "✅ Debug complete!"

