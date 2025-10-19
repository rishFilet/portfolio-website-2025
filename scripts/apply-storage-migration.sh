#!/bin/bash

# Apply Storage Migration
# This creates storage buckets and policies for image uploads

echo "📦 Apply Storage Buckets Migration"
echo ""
echo "This will create storage buckets for images, hero images, logos, and favicons."
echo ""

# Ask if local or production
echo "Which database do you want to apply this to?"
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
echo "📦 Applying storage buckets migration..."

psql "$CONN_STRING" < "$(dirname "$0")/../supabase/migrations/20241201000005_create_storage_buckets.sql"

if [ $? -eq 0 ]; then
  echo "✅ Storage buckets migration applied!"
else
  echo "⚠️  Storage migration may have already been applied or failed"
  echo "    Run ./scripts/check-storage-buckets.sh to verify"
fi

echo ""
echo "🎉 Storage setup complete!"
echo ""
echo "📌 Buckets created:"
echo "   - images (5MB limit)"
echo "   - hero-images (10MB limit)"
echo "   - logos (2MB limit)"
echo "   - favicons (1MB limit)"
echo "   - theme-logos (2MB limit)"
echo "   - theme-hero-images (10MB limit)"
echo ""
echo "🔐 All buckets are PUBLIC and allow:"
echo "   - Anyone can view images"
echo "   - Authenticated users can upload/edit/delete"

