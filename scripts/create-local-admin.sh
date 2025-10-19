#!/bin/bash
# Create admin user in local Supabase

echo "======================================"
echo "Create Local Admin User"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if Supabase is running
if ! supabase status &> /dev/null; then
    echo -e "${YELLOW}⚠ Local Supabase is not running${NC}"
    echo ""
    echo "Start it with: ./scripts/setup-local-supabase.sh"
    exit 1
fi

echo -e "${GREEN}✓ Local Supabase is running${NC}"
echo ""

# Prompt for email and password
read -p "Enter admin email (default: admin@localhost.com): " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@localhost.com}

read -s -p "Enter admin password (default: admin123): " ADMIN_PASSWORD
echo ""
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin123}

echo ""
echo "Creating user: $ADMIN_EMAIL"
echo ""

# Create user using SQL
supabase db execute << EOF
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  raw_app_meta_data,
  raw_user_meta_data
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  '$ADMIN_EMAIL',
  crypt('$ADMIN_PASSWORD', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '',
  '{"provider":"email","providers":["email"]}',
  '{}'
)
ON CONFLICT (email) DO NOTHING;
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Admin user created successfully!${NC}"
    echo ""
    echo "Login credentials:"
    echo "  Email: $ADMIN_EMAIL"
    echo "  Password: $ADMIN_PASSWORD"
    echo ""
    echo "Go to: ${BLUE}http://localhost:3000/login${NC}"
    echo "(or whatever port your dev server is using)"
else
    echo ""
    echo -e "${YELLOW}⚠ User might already exist or there was an error${NC}"
fi


