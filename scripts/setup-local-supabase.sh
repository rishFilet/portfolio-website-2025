#!/bin/bash
# Setup Local Supabase for Development

echo "======================================"
echo "Setup Local Supabase Instance"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is installed
echo "Step 1: Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    echo ""
    echo "Please install Docker Desktop first:"
    echo "https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker is not running${NC}"
    echo ""
    echo "Please start Docker Desktop and try again"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed and running${NC}"
echo ""

# Check if Supabase CLI is installed
echo "Step 2: Checking Supabase CLI..."
if ! command -v supabase &> /dev/null; then
    echo -e "${YELLOW}⚠ Supabase CLI not found. Installing...${NC}"
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install supabase/tap/supabase
        else
            echo -e "${RED}Homebrew not found. Please install it first:${NC}"
            echo "https://brew.sh/"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
        sudo mv supabase /usr/local/bin/supabase
    else
        echo -e "${RED}Unsupported OS. Please install Supabase CLI manually:${NC}"
        echo "https://supabase.com/docs/guides/cli"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Supabase CLI is installed${NC}"
supabase --version
echo ""

# Initialize Supabase in the project
echo "Step 3: Initializing Supabase..."
cd "$(dirname "$0")/.." || exit

if [ -d "supabase" ]; then
    echo -e "${YELLOW}⚠ Supabase directory already exists${NC}"
    read -p "Do you want to reinitialize? (y/n): " REINIT
    if [ "$REINIT" = "y" ]; then
        rm -rf supabase
        supabase init
    fi
else
    supabase init
fi

echo -e "${GREEN}✓ Supabase initialized${NC}"
echo ""

# Copy migrations
echo "Step 4: Setting up database migrations..."
if [ -d "backend-supabase/supabase/migrations" ]; then
    cp backend-supabase/supabase/migrations/* supabase/migrations/ 2>/dev/null || true
    echo -e "${GREEN}✓ Migrations copied${NC}"
else
    echo -e "${YELLOW}⚠ No migrations found in backend-supabase${NC}"
fi
echo ""

# Start Supabase
echo "Step 5: Starting Supabase (this may take a few minutes)..."
echo ""
supabase start

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Local Supabase is running!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Get the credentials
    API_URL=$(supabase status | grep "API URL" | awk '{print $3}')
    ANON_KEY=$(supabase status | grep "anon key" | awk '{print $3}')
    SERVICE_ROLE_KEY=$(supabase status | grep "service_role key" | awk '{print $3}')
    
    echo "Your local Supabase credentials:"
    echo ""
    echo "API URL: $API_URL"
    echo "Studio URL: http://localhost:54323"
    echo ""
    echo "Creating .env.local.development file..."
    
    cat > frontend/.env.local.development << EOF
# Site URL for metadata
NEXT_PUBLIC_SITE_URL=http://localhost:3000

# Local Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=$API_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
EOF
    
    echo -e "${GREEN}✓ Credentials saved to frontend/.env.local.development${NC}"
    echo ""
    echo "To use local Supabase:"
    echo "1. Copy the .env.local.development to .env.local:"
    echo "   ${BLUE}cp frontend/.env.local.development frontend/.env.local${NC}"
    echo ""
    echo "2. Create an admin user:"
    echo "   ${BLUE}./scripts/create-local-admin.sh${NC}"
    echo ""
    echo "3. Access Supabase Studio at: ${BLUE}http://localhost:54323${NC}"
    echo ""
    echo "4. Restart your dev server:"
    echo "   ${BLUE}cd frontend && npm run dev${NC}"
    echo ""
    echo "To stop Supabase: ${BLUE}supabase stop${NC}"
    echo "To restart: ${BLUE}supabase start${NC}"
    echo ""
else
    echo -e "${RED}✗ Failed to start Supabase${NC}"
    exit 1
fi


