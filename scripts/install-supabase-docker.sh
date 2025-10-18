#!/bin/bash

# Supabase Docker Installation Script
# This script sets up a self-hosted Supabase instance in Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓ ${NC}$1"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${NC}$1"
}

print_error() {
    echo -e "${RED}✗ ${NC}$1"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_success "Docker is installed"
}

# Check if Git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi
    print_success "Git is installed"
}

# Generate a random string
generate_random_string() {
    local length=${1:-32}
    LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c $length
}

# Generate JWT secret
generate_jwt_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-64
}

# Main installation
print_header "Supabase Docker Installation"

echo "This script will set up a self-hosted Supabase instance using Docker."
echo ""

# Check prerequisites
print_info "Checking prerequisites..."
check_docker
check_git
echo ""

# Get instance name
print_header "Configuration"
read -p "Enter a name for your Supabase instance (alphanumeric, no spaces): " INSTANCE_NAME

# Validate instance name
if [[ ! "$INSTANCE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    print_error "Invalid instance name. Use only letters, numbers, hyphens, and underscores."
    exit 1
fi

print_success "Instance name: $INSTANCE_NAME"
echo ""

# Get installation directory
DEFAULT_DIR="$HOME/supabase-$INSTANCE_NAME"
read -p "Installation directory [$DEFAULT_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_DIR}

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
print_success "Installation directory: $INSTALL_DIR"
echo ""

# Get server configuration
print_info "Server Configuration"
read -p "Enter your server's IP address or domain [localhost]: " SERVER_HOST
SERVER_HOST=${SERVER_HOST:-localhost}

read -p "Enter Studio port [3001]: " STUDIO_PORT
STUDIO_PORT=${STUDIO_PORT:-3001}

read -p "Enter API port [8000]: " API_PORT
API_PORT=${API_PORT:-8000}

read -p "Enter PostgreSQL port [5432]: " DB_PORT
DB_PORT=${DB_PORT:-5432}

echo ""

# Generate secrets
print_info "Generating secure secrets..."
POSTGRES_PASSWORD=$(generate_random_string 32)
JWT_SECRET=$(generate_jwt_secret)
ANON_KEY=$(generate_random_string 64)
SERVICE_ROLE_KEY=$(generate_random_string 64)
DASHBOARD_PASSWORD=$(generate_random_string 16)

print_success "Secrets generated"
echo ""

# Clone Supabase repository
print_info "Downloading Supabase Docker setup..."
if [ -d "supabase" ]; then
    print_warning "Supabase directory already exists, using existing setup"
    cd supabase
else
    git clone --depth 1 https://github.com/supabase/supabase
    cd supabase/docker
    print_success "Supabase downloaded"
fi
echo ""

# Copy example env file
print_info "Creating environment configuration..."
if [ ! -f ".env" ]; then
    cp .env.example .env 2>/dev/null || cat > .env << 'EOF'
# Supabase Configuration

POSTGRES_PASSWORD=your-super-secret-and-long-postgres-password
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
ANON_KEY=your-anon-key
SERVICE_ROLE_KEY=your-service-role-key

# Studio
STUDIO_DEFAULT_ORGANIZATION=Default Organization
STUDIO_DEFAULT_PROJECT=Default Project

# Database
POSTGRES_HOST=db
POSTGRES_DB=postgres
POSTGRES_PORT=5432

# API
API_EXTERNAL_URL=http://localhost:8000

# Studio
STUDIO_PORT=3000
STUDIO_PG_META_PORT=8080

# Dashboard
DASHBOARD_USERNAME=supabase
DASHBOARD_PASSWORD=this_password_is_insecure_and_should_be_updated
EOF
fi

# Update .env file with generated values
sed -i.bak "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" .env
sed -i.bak "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
sed -i.bak "s|ANON_KEY=.*|ANON_KEY=$ANON_KEY|" .env
sed -i.bak "s|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env
sed -i.bak "s|DASHBOARD_PASSWORD=.*|DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD|" .env
sed -i.bak "s|API_EXTERNAL_URL=.*|API_EXTERNAL_URL=http://$SERVER_HOST:$API_PORT|" .env
sed -i.bak "s|STUDIO_PORT=.*|STUDIO_PORT=$STUDIO_PORT|" .env

# Update docker-compose to use custom container names
print_info "Configuring Docker containers..."
if [ -f "docker-compose.yml" ]; then
    # Add container names to docker-compose
    sed -i.bak "s|container_name: supabase-|container_name: ${INSTANCE_NAME}-|g" docker-compose.yml || true
fi

rm -f .env.bak docker-compose.yml.bak 2>/dev/null || true

print_success "Environment configured"
echo ""

# Start Supabase
print_header "Starting Supabase"
print_info "This may take a few minutes on first run..."
echo ""

docker-compose pull
docker-compose up -d

print_success "Supabase containers started!"
echo ""

# Wait for services to be ready
print_info "Waiting for services to be ready (this may take 30-60 seconds)..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_success "Services are running!"
else
    print_warning "Some services may still be starting. Check with: docker-compose ps"
fi
echo ""

# Create credentials file
CREDENTIALS_FILE="$INSTALL_DIR/supabase-credentials.txt"
cat > "$CREDENTIALS_FILE" << EOF
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          SUPABASE INSTANCE: $INSTANCE_NAME
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

🔐 CREDENTIALS (SAVE THESE SECURELY!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Access URLs:
   Studio (Admin Panel):  http://$SERVER_HOST:$STUDIO_PORT
   API URL:               http://$SERVER_HOST:$API_PORT
   Database:              postgresql://postgres:$POSTGRES_PASSWORD@$SERVER_HOST:$DB_PORT/postgres

🔑 API Keys (for .env.local in frontend):
   NEXT_PUBLIC_SUPABASE_URL=http://$SERVER_HOST:$API_PORT
   NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY

🗄️  Database Credentials:
   Host:          $SERVER_HOST
   Port:          $DB_PORT
   Database:      postgres
   Username:      postgres
   Password:      $POSTGRES_PASSWORD

🎛️  Studio Dashboard:
   Username:      supabase
   Password:      $DASHBOARD_PASSWORD

🔐 JWT Secret:   $JWT_SECRET

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Installation Directory: $INSTALL_DIR/supabase/docker

⚠️  IMPORTANT SECURITY NOTES:
   - Store these credentials securely
   - Never commit credentials to git
   - Change the dashboard password after first login
   - Use strong passwords in production
   - Configure firewall rules to restrict access

🛠️  USEFUL COMMANDS:
   
   View logs:           cd $INSTALL_DIR/supabase/docker && docker-compose logs -f
   Stop Supabase:       cd $INSTALL_DIR/supabase/docker && docker-compose down
   Start Supabase:      cd $INSTALL_DIR/supabase/docker && docker-compose up -d
   Restart Supabase:    cd $INSTALL_DIR/supabase/docker && docker-compose restart
   View status:         cd $INSTALL_DIR/supabase/docker && docker-compose ps
   
   Remove everything:   cd $INSTALL_DIR/supabase/docker && docker-compose down -v
                        (Warning: This deletes all data!)

📚 Next Steps:
   1. Access Studio at http://$SERVER_HOST:$STUDIO_PORT
   2. Copy the API keys to your frontend/.env.local file
   3. Run the database migrations (see ADMIN_SETUP_GUIDE.md)
   4. Create your admin user in the Authentication section

EOF

# Display credentials
cat "$CREDENTIALS_FILE"
echo ""

print_success "Installation complete!"
print_info "Credentials saved to: $CREDENTIALS_FILE"
echo ""

print_warning "⚠️  SECURITY REMINDER:"
echo "   This file contains sensitive credentials. Keep it secure!"
echo "   Consider encrypting it or moving it to a secure location."
echo ""

# Create management script
MANAGE_SCRIPT="$INSTALL_DIR/manage-supabase.sh"
cat > "$MANAGE_SCRIPT" << EOF
#!/bin/bash
# Supabase Management Script for $INSTANCE_NAME

SUPABASE_DIR="$INSTALL_DIR/supabase/docker"

case "\$1" in
    start)
        echo "Starting Supabase ($INSTANCE_NAME)..."
        cd "\$SUPABASE_DIR" && docker-compose up -d
        ;;
    stop)
        echo "Stopping Supabase ($INSTANCE_NAME)..."
        cd "\$SUPABASE_DIR" && docker-compose down
        ;;
    restart)
        echo "Restarting Supabase ($INSTANCE_NAME)..."
        cd "\$SUPABASE_DIR" && docker-compose restart
        ;;
    logs)
        echo "Showing logs for Supabase ($INSTANCE_NAME)..."
        cd "\$SUPABASE_DIR" && docker-compose logs -f
        ;;
    status)
        echo "Status of Supabase ($INSTANCE_NAME)..."
        cd "\$SUPABASE_DIR" && docker-compose ps
        ;;
    credentials)
        cat "$CREDENTIALS_FILE"
        ;;
    *)
        echo "Supabase Management Script for $INSTANCE_NAME"
        echo ""
        echo "Usage: \$0 {start|stop|restart|logs|status|credentials}"
        echo ""
        echo "  start       - Start Supabase containers"
        echo "  stop        - Stop Supabase containers"
        echo "  restart     - Restart Supabase containers"
        echo "  logs        - View Supabase logs (Ctrl+C to exit)"
        echo "  status      - Check container status"
        echo "  credentials - Display credentials"
        exit 1
        ;;
esac
EOF

chmod +x "$MANAGE_SCRIPT"
print_success "Management script created: $MANAGE_SCRIPT"
echo ""

print_info "You can now manage your Supabase instance with:"
echo "   $MANAGE_SCRIPT {start|stop|restart|logs|status|credentials}"
echo ""

print_header "Installation Summary"
print_success "Supabase instance '$INSTANCE_NAME' is ready!"
echo ""
echo "Access your Supabase Studio at: http://$SERVER_HOST:$STUDIO_PORT"
echo ""
print_info "Next steps:"
echo "   1. Open Studio and verify everything is working"
echo "   2. Copy the API keys to your frontend/.env.local"
echo "   3. Run database migrations"
echo "   4. Create your admin user"
echo ""
print_info "See ADMIN_SETUP_GUIDE.md for detailed instructions"
echo ""


