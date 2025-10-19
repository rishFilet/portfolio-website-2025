#!/bin/bash

# Check RLS Policies Script
# This script verifies that RLS policies are properly set up

echo "🔍 Checking RLS Policies for Production Database"
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

echo "📋 Checking if RLS is enabled on tables..."
echo ""

psql "$CONN_STRING" << 'EOF'
-- Check RLS status on all tables
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'landing_page_content',
    'blog_posts',
    'project_posts',
    'social_links',
    'tags',
    'technologies',
    'site_settings',
    'about_ventures',
    'about_experiences',
    'about_hobbies',
    'about_values'
  )
ORDER BY tablename;

\echo ''
\echo '📜 Checking RLS policies...'
\echo ''

-- Check policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

\echo ''
\echo '👤 Checking authenticated users...'
\echo ''

-- Check if there are any authenticated users
SELECT 
  id,
  email,
  role,
  aud,
  email_confirmed_at IS NOT NULL as email_confirmed
FROM auth.users;

EOF

echo ""
echo "✅ Check complete!"
echo ""
echo "🔧 If RLS is not enabled or policies are missing, run the migration:"
echo "   psql \"$CONN_STRING\" < supabase/migrations/20241201000001_enhanced_portfolio_schema.sql"

