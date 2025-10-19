#!/bin/bash

# Check Storage Buckets
# This script verifies storage buckets are properly configured

echo "🪣 Checking Storage Buckets"
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
echo "📋 Checking storage buckets..."
echo ""

psql "$CONN_STRING" << 'EOF'
-- Check if buckets exist
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
ORDER BY name;

\echo ''
\echo '🔒 Checking storage policies...'
\echo ''

-- Check storage policies
SELECT 
  policyname,
  cmd as operation,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

\echo ''
\echo '📁 Checking uploaded files...'
\echo ''

-- Count files in each bucket
SELECT 
  bucket_id,
  COUNT(*) as file_count,
  pg_size_pretty(SUM(COALESCE((metadata->>'size')::bigint, 0))) as total_size
FROM storage.objects
GROUP BY bucket_id
ORDER BY bucket_id;

EOF

echo ""
echo "✅ Check complete!"
echo ""
echo "📌 Notes:"
echo "   - Buckets should have 'public = t' for public access"
echo "   - Storage policies should allow SELECT for public"
echo "   - If buckets are missing, run: ./scripts/apply-storage-migration.sh"

