#!/bin/bash
# Supabase Storage Troubleshooting Script

echo "======================================"
echo "Supabase Storage Troubleshooting"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "This script helps diagnose Supabase Storage issues."
echo "Run this on your server where Supabase is installed."
echo ""

# Check if running on server or locally
read -p "Are you running this on the Supabase server? (y/n): " ON_SERVER

if [ "$ON_SERVER" != "y" ]; then
    echo ""
    echo -e "${YELLOW}Please run this script on your Supabase server:${NC}"
    echo "1. SSH to your server: ssh your-server"
    echo "2. Copy this script there"
    echo "3. Run: bash check-supabase-storage.sh"
    echo ""
    echo "Or check manually with these commands:"
    echo ""
    echo "  # Check if storage container is running:"
    echo "  docker ps | grep storage"
    echo ""
    echo "  # Check storage logs:"
    echo "  docker logs supabase-storage 2>&1 | tail -50"
    echo ""
    echo "  # Check if storage port is accessible:"
    echo "  curl http://localhost:5000/status"
    echo ""
    exit 0
fi

echo ""
echo "Step 1: Checking Docker containers..."
echo "--------------------------------------"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    echo "Please install Docker first"
    exit 1
fi

# Check for Supabase containers
STORAGE_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i storage | head -1)

if [ -z "$STORAGE_CONTAINER" ]; then
    echo -e "${RED}✗ Storage container not found${NC}"
    echo ""
    echo "Available containers:"
    docker ps --format 'table {{.Names}}\t{{.Status}}'
    echo ""
    echo -e "${YELLOW}The storage service might not be running.${NC}"
    echo "Check your docker-compose.yml for the storage service."
else
    echo -e "${GREEN}✓ Storage container found: $STORAGE_CONTAINER${NC}"
    
    # Check if it's running
    STORAGE_STATUS=$(docker ps --filter "name=$STORAGE_CONTAINER" --format '{{.Status}}')
    echo "  Status: $STORAGE_STATUS"
fi

echo ""
echo "Step 2: Checking storage service health..."
echo "-------------------------------------------"

if [ -n "$STORAGE_CONTAINER" ]; then
    echo "Checking storage logs (last 20 lines):"
    docker logs "$STORAGE_CONTAINER" 2>&1 | tail -20
    echo ""
    
    # Try to access storage API
    echo "Testing storage API endpoint..."
    STORAGE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/status 2>/dev/null)
    
    if [ "$STORAGE_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ Storage API is responding${NC}"
    else
        echo -e "${RED}✗ Storage API not responding (HTTP $STORAGE_RESPONSE)${NC}"
        echo "  Storage might not be accessible through Kong gateway"
    fi
fi

echo ""
echo "Step 3: Checking environment variables..."
echo "------------------------------------------"

# Find .env file
if [ -f ".env" ]; then
    echo "Found .env file"
    
    # Check critical storage env vars
    if grep -q "STORAGE_BACKEND" .env; then
        echo -e "${GREEN}✓ STORAGE_BACKEND configured${NC}"
    else
        echo -e "${YELLOW}⚠ STORAGE_BACKEND not found${NC}"
    fi
    
    if grep -q "GLOBAL_S3_BUCKET" .env; then
        echo -e "${GREEN}✓ GLOBAL_S3_BUCKET configured${NC}"
    else
        echo -e "${YELLOW}⚠ GLOBAL_S3_BUCKET not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ .env file not found in current directory${NC}"
    echo "  Please cd to your Supabase installation directory"
fi

echo ""
echo "======================================"
echo "Recommendations:"
echo "======================================"
echo ""
echo "If storage is not working, you can:"
echo ""
echo "1. ${GREEN}Use external image hosting${NC} (Cloudinary, ImgBB, etc.)"
echo "   - Easiest solution"
echo "   - No bucket needed"
echo "   - Just paste URLs in admin panel"
echo ""
echo "2. ${GREEN}Use Next.js public folder${NC}"
echo "   - Store images in: frontend/public/images/"
echo "   - Reference as: /images/your-image.jpg"
echo ""
echo "3. ${YELLOW}Fix storage service${NC}"
echo "   - Restart containers: docker-compose restart storage"
echo "   - Check logs: docker logs $STORAGE_CONTAINER"
echo "   - Verify Kong routing is correct"
echo ""

