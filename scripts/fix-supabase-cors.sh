#!/bin/bash
# Fix CORS issues in Supabase

echo "======================================"
echo "Fix Supabase CORS Configuration"
echo "======================================"
echo ""

cat << 'EOF'
Your Supabase needs to allow requests from your frontend.

Run these commands on your Supabase server:

1. SSH to your server:
   ssh your-server

2. Find your Supabase installation directory:
   cd /path/to/supabase

3. Edit the .env file:
   nano .env
   
   Or if using docker-compose:
   nano docker-compose.yml

4. Add/Update these environment variables:

   For Kong Gateway (API Gateway):
   ================================
   ADDITIONAL_REDIRECT_URLS=http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:3003
   SITE_URL=http://localhost:3002
   
   For GoTrue (Auth service):
   ================================
   GOTRUE_SITE_URL=http://localhost:3002
   GOTRUE_URI_ALLOW_LIST=http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:3003
   
   Or if you see JWT_SECRET:
   API_EXTERNAL_URL=https://supabase.rishikhan.dev
   
5. Restart services:
   docker-compose restart
   
   Or restart specific services:
   docker-compose restart kong gotrue

6. Test again at: http://localhost:3002/login

EOF

echo ""
echo "======================================"
echo "Quick Fix Alternative:"
echo "======================================"
echo ""
echo "If you can't modify the server, you can:"
echo "1. Deploy your frontend to a domain (e.g., https://portfolio.rishikhan.dev)"
echo "2. Update NEXT_PUBLIC_SITE_URL in .env.local to match"
echo "3. Add that domain to Supabase allowed origins"
echo ""
echo "Or for development:"
echo "1. Use a browser extension like 'CORS Unblock' (Chrome/Firefox)"
echo "2. Only for development - NOT for production!"
echo ""


