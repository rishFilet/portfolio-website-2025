# Scripts Directory

This directory contains utility scripts for setting up and managing your portfolio website.

## Available Scripts

### `install-supabase-docker.sh`

Automated installation script for setting up a self-hosted Supabase instance using Docker.

**What it does:**

- ✅ Checks prerequisites (Docker, Git)
- ✅ Prompts for instance name and configuration
- ✅ Generates secure credentials (passwords, JWT secrets, API keys)
- ✅ Downloads and configures Supabase Docker setup
- ✅ Creates Docker containers with custom names
- ✅ Starts all Supabase services
- ✅ Generates credentials file for easy reference
- ✅ Creates management script for easy control

**Usage:**

```bash
cd /Users/rishfilet/Projects/portfolio-website-2025
./scripts/install-supabase-docker.sh
```

**Interactive Prompts:**

1. **Instance Name**: Used for container naming and identification (e.g., `portfolio-prod`)
2. **Installation Directory**: Where to install Supabase (default: `~/supabase-[instance-name]`)
3. **Server Host**: Your server's IP or domain (default: `localhost`)
4. **Ports**: Studio, API, and Database ports (defaults: 3001, 8000, 5432)

**Output:**

- Supabase containers running with custom names
- Credentials file: `~/supabase-[instance-name]/supabase-credentials.txt`
- Management script: `~/supabase-[instance-name]/manage-supabase.sh`

**Requirements:**

- Docker and Docker Compose installed
- Git installed
- At least 2GB RAM (4GB recommended)
- 10GB free disk space
- Bash shell

**Example:**

```bash
$ ./scripts/install-supabase-docker.sh

═══════════════════════════════════════════════════════
  Supabase Docker Installation
═══════════════════════════════════════════════════════

This script will set up a self-hosted Supabase instance using Docker.

ℹ Checking prerequisites...
✓ Docker is installed
✓ Git is installed

═══════════════════════════════════════════════════════
  Configuration
═══════════════════════════════════════════════════════

Enter a name for your Supabase instance (alphanumeric, no spaces): portfolio-prod
✓ Instance name: portfolio-prod

Installation directory [/Users/you/supabase-portfolio-prod]:
✓ Installation directory: /Users/you/supabase-portfolio-prod

ℹ Server Configuration
Enter your server's IP address or domain [localhost]: 192.168.1.100
Enter Studio port [3001]:
Enter API port [8000]:
Enter PostgreSQL port [5432]:

ℹ Generating secure secrets...
✓ Secrets generated
...
```

**Generated Files:**

1. **Credentials File** (`supabase-credentials.txt`):

   ```
   Contains:
   - Access URLs (Studio, API, Database)
   - API Keys (anon, service role)
   - Database credentials
   - Studio dashboard login
   - JWT secret
   - Useful commands
   ```

2. **Management Script** (`manage-supabase.sh`):

   ```bash
   # Start Supabase
   ./manage-supabase.sh start

   # Stop Supabase
   ./manage-supabase.sh stop

   # Restart Supabase
   ./manage-supabase.sh restart

   # View logs
   ./manage-supabase.sh logs

   # Check status
   ./manage-supabase.sh status

   # Show credentials
   ./manage-supabase.sh credentials
   ```

**Security Notes:**

- All credentials are randomly generated and cryptographically secure
- Credentials file contains sensitive information - store it securely
- Never commit credentials to version control
- Change the Studio dashboard password after first login
- Configure firewall rules to restrict access in production
- Use HTTPS with a reverse proxy in production

**Troubleshooting:**

If the script fails:

1. Check Docker is running: `docker ps`
2. Verify ports aren't in use: `lsof -i :3001` (etc.)
3. Check logs: `docker-compose logs`
4. Ensure sufficient disk space: `df -h`
5. Try running with `bash -x` for detailed output

**Advanced Configuration:**

After installation, you can modify:

- Ports: Edit `.env` file in the Docker directory
- Container names: Edit `docker-compose.yml`
- Memory limits: Add resource constraints to `docker-compose.yml`

**Uninstalling:**

To completely remove the Supabase instance:

```bash
cd ~/supabase-[instance-name]/supabase/docker
docker-compose down -v  # Removes containers and volumes
cd ~
rm -rf ~/supabase-[instance-name]  # Removes all files
```

**Production Deployment:**

For production use:

1. Use a reverse proxy (nginx/Caddy) for HTTPS
2. Set up regular database backups
3. Configure firewall rules
4. Use strong, unique passwords
5. Monitor resource usage
6. Consider using Docker Swarm or Kubernetes for high availability

## Future Scripts

Additional scripts may be added for:

- Database backup automation
- SSL certificate setup
- Migration rollback
- Data export/import
- Health monitoring

## Contributing

When adding new scripts:

1. Make them executable: `chmod +x script-name.sh`
2. Add proper error handling
3. Use colored output for clarity
4. Document in this README
5. Test on clean system

