#!/bin/bash
# Script to create an admin user in Supabase

echo "======================================"
echo "Create Supabase Admin User"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will create an admin user for your portfolio.${NC}"
echo ""

# Prompt for email
read -p "Enter admin email: " ADMIN_EMAIL
if [ -z "$ADMIN_EMAIL" ]; then
    echo -e "${RED}Error: Email is required${NC}"
    exit 1
fi

# Prompt for password
read -s -p "Enter admin password: " ADMIN_PASSWORD
echo ""
if [ -z "$ADMIN_PASSWORD" ]; then
    echo -e "${RED}Error: Password is required${NC}"
    exit 1
fi

# Confirm password
read -s -p "Confirm password: " ADMIN_PASSWORD_CONFIRM
echo ""
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords do not match${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Creating user...${NC}"
echo ""

# Ask for connection method
echo "How do you want to connect to Supabase?"
echo "1) Direct connection (provide connection string)"
echo "2) SSH tunnel (connect through your server)"
echo "3) Generate SQL only (I'll run it manually)"
read -p "Choose [1-3]: " CONNECTION_METHOD

case $CONNECTION_METHOD in
    1)
        echo ""
        echo "Enter your Supabase database connection string:"
        echo "Format: postgresql://postgres:[password]@[host]:[port]/postgres"
        read -p "Connection string: " DB_CONNECTION
        
        if [ -z "$DB_CONNECTION" ]; then
            echo -e "${RED}Error: Connection string is required${NC}"
            exit 1
        fi
        
        # Try to connect and create user
        PGPASSWORD="" psql "$DB_CONNECTION" << EOF
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
);

SELECT id, email, created_at FROM auth.users WHERE email = '$ADMIN_EMAIL';
EOF
        ;;
        
    2)
        echo ""
        read -p "Enter your server SSH address (user@host): " SSH_ADDRESS
        read -p "Enter Supabase DB port on server (default: 5432): " DB_PORT
        DB_PORT=${DB_PORT:-5432}
        
        echo ""
        echo -e "${BLUE}Connecting via SSH...${NC}"
        
        ssh -t "$SSH_ADDRESS" "psql -U postgres -p $DB_PORT -d postgres" << EOF
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
);

SELECT id, email, created_at FROM auth.users WHERE email = '$ADMIN_EMAIL';
EOF
        ;;
        
    3)
        echo ""
        echo -e "${GREEN}SQL generated!${NC}"
        echo ""
        echo "Copy and run this in your Supabase SQL Editor:"
        echo "----------------------------------------"
        cat << EOF
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
);

-- Verify the user was created
SELECT id, email, created_at FROM auth.users WHERE email = '$ADMIN_EMAIL';
EOF
        echo "----------------------------------------"
        echo ""
        echo "After running this SQL:"
        echo "1. Go to: ${GREEN}http://localhost:3002/login${NC}"
        echo "2. Log in with:"
        echo "   Email: $ADMIN_EMAIL"
        echo "   Password: (the one you entered)"
        echo ""
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ User created successfully!${NC}"
    echo ""
    echo "You can now log in at:"
    echo -e "${BLUE}http://localhost:3002/login${NC}"
    echo ""
    echo "Credentials:"
    echo "  Email: $ADMIN_EMAIL"
    echo "  Password: (the one you entered)"
else
    echo ""
    echo -e "${RED}✗ Failed to create user${NC}"
    echo ""
    echo "You can try option 3 to generate SQL and run it manually in Supabase Studio"
fi


