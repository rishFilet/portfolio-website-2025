# Portfolio Admin Panel Setup Guide

This guide will walk you through setting up the admin panel for your portfolio website, from database setup to managing content.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Choose Your Setup](#choose-your-setup)
   - [Option A: Self-Hosted (Docker)](#option-a-self-hosted-docker)
   - [Option B: Supabase Cloud](#option-b-supabase-cloud)
3. [Database Setup](#database-setup)
4. [Frontend Configuration](#frontend-configuration)
5. [Creating Admin User](#creating-admin-user)
6. [Running the Application](#running-the-application)
7. [Using the Admin Panel](#using-the-admin-panel)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- Node.js 18+ and pnpm installed
- Git installed (for version control)
- **For self-hosted**: Docker and Docker Compose installed
- **For cloud**: A Supabase account (free tier is sufficient)

---

## Choose Your Setup

You have two options for hosting your Supabase backend:

### Option A: Self-Hosted (Docker)

**Recommended for**: Those who want full control, have a dedicated server, or prefer self-hosting.

**Advantages**:

- ✅ Complete control over your data
- ✅ No vendor lock-in
- ✅ Free (just server costs)
- ✅ Can run on your own infrastructure

**Requirements**:

- A server with Docker installed (Linux, macOS, or Windows)
- At least 2GB RAM (4GB recommended)
- 10GB free disk space

**Installation Steps**:

1. **Run the installation script**:

   ```bash
   cd /Users/rishfilet/Projects/portfolio-website-2025
   ./scripts/install-supabase-docker.sh
   ```

2. **Follow the prompts**:

   - Enter an instance name (e.g., `portfolio-prod`)
   - Specify installation directory (or use default)
   - Enter your server's IP address or domain
   - Configure ports (or use defaults: Studio=3001, API=8000, DB=5432)

3. **Wait for installation** (2-5 minutes):

   - The script will download Supabase
   - Generate secure credentials
   - Start all Docker containers
   - Create a credentials file

4. **Save your credentials**:

   - A file named `supabase-credentials.txt` will be created
   - **Store this securely** - it contains all your access keys
   - You'll need these for your `.env.local` file

5. **Verify installation**:

   ```bash
   # Check that containers are running
   docker ps | grep portfolio-prod  # (use your instance name)

   # Or use the management script
   ~/supabase-portfolio-prod/manage-supabase.sh status
   ```

6. **Access Supabase Studio**:
   - Open http://your-server-ip:3001 in your browser
   - Login with the credentials from the credentials file
   - You should see the Supabase dashboard

**Management Commands**:

The installation script creates a management script for easy control:

```bash
# Start Supabase
~/supabase-[instance-name]/manage-supabase.sh start

# Stop Supabase
~/supabase-[instance-name]/manage-supabase.sh stop

# Restart Supabase
~/supabase-[instance-name]/manage-supabase.sh restart

# View logs
~/supabase-[instance-name]/manage-supabase.sh logs

# Check status
~/supabase-[instance-name]/manage-supabase.sh status

# Show credentials
~/supabase-[instance-name]/manage-supabase.sh credentials
```

**Important Notes**:

- Your Supabase API URL will be: `http://your-server:8000`
- For production, use HTTPS with a reverse proxy (nginx/Caddy)
- Configure your firewall to only expose necessary ports
- Regularly backup your PostgreSQL database

**Skip to**: [Database Setup](#database-setup)

---

### Option B: Supabase Cloud

**Recommended for**: Quick setup, no server management, production-ready infrastructure.

**Advantages**:

- ✅ Fully managed (no maintenance)
- ✅ Built-in backups
- ✅ Global CDN
- ✅ Free tier available

**Step 1: Create a Supabase Project**

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Click **"New Project"**
3. Fill in the details:
   - **Name**: My Portfolio
   - **Database Password**: Choose a strong password (save this!)
   - **Region**: Select the closest region to your users
4. Click **"Create new project"**
5. Wait 2-3 minutes for the project to be provisioned

**Step 2: Get Your API Keys**

1. In your Supabase project dashboard, go to **Settings** → **API**
2. You'll need these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)
   - **service_role key** (starts with `eyJ...`) - Click "Reveal" to see it

---

## Database Setup

### Step 3: Run Database Migrations

Run the database migrations to create all necessary tables and configure security.

#### For Self-Hosted (Docker) Setup:

**Option A: Using psql (Command Line)**:

```bash
# Get your database password from credentials
~/supabase-[instance-name]/manage-supabase.sh credentials

# Connect to database (replace PASSWORD with your actual password)
PGPASSWORD=YOUR_PASSWORD psql -h localhost -p 5432 -U postgres -d postgres

# Inside psql, run the migrations
\i /Users/rishfilet/Projects/portfolio-website-2025/backend-supabase/supabase/migrations/20241201000000_initial_schema.sql
\i /Users/rishfilet/Projects/portfolio-website-2025/backend-supabase/supabase/migrations/20241201000001_enhanced_portfolio_schema.sql

# Exit
\q
```

**Option B: Using Supabase Studio UI**:

1. Open http://your-server-ip:3001
2. Go to **SQL Editor**
3. Click **"New Query"**
4. Copy and paste contents of `20241201000000_initial_schema.sql`
5. Click **"Run"**
6. Repeat for `20241201000001_enhanced_portfolio_schema.sql`

#### For Cloud Setup:

**Option A: Using Supabase CLI (Recommended)**:

1. Install Supabase CLI:

   ```bash
   npm install -g supabase
   ```

2. Link your project:

   ```bash
   cd /Users/rishfilet/Projects/portfolio-website-2025/backend-supabase
   supabase link --project-ref YOUR_PROJECT_REF
   ```

   Replace `YOUR_PROJECT_REF` with your project reference (found in Project Settings → General)

3. Run migrations:
   ```bash
   supabase db push
   ```

**Option B: Using SQL Editor**:

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Copy the contents of `backend-supabase/supabase/migrations/20241201000000_initial_schema.sql`
4. Paste into the SQL Editor and click **"Run"**
5. Repeat for `backend-supabase/supabase/migrations/20241201000001_enhanced_portfolio_schema.sql`

### Step 4: Verify Database Setup

1. Go to **Database** → **Tables** in your Supabase dashboard
2. You should see these tables:

   - `blog_posts`
   - `blog_post_images`
   - `project_posts`
   - `project_post_images`
   - `landing_page_content`
   - `about_ventures`
   - `about_experiences`
   - `about_hobbies`
   - `about_values`
   - `social_links`
   - `site_settings`
   - `tags`
   - `technologies`
   - `content_history`

3. Go to **Storage** and create a bucket named `portfolio-images`:

   - Click **"New bucket"**
   - Name: `portfolio-images`
   - **Public bucket**: ✅ Yes
   - Click **"Create bucket"**

4. Set storage policies:

   - Click on the `portfolio-images` bucket
   - Go to **Policies**
   - Click **"New Policy"**
   - Select **"Custom policy"**
   - Add these policies:

   **Allow public read access:**

   ```sql
   CREATE POLICY "Public Access"
   ON storage.objects FOR SELECT
   USING ( bucket_id = 'portfolio-images' );
   ```

   **Allow authenticated users to upload:**

   ```sql
   CREATE POLICY "Authenticated users can upload"
   ON storage.objects FOR INSERT
   WITH CHECK (
     bucket_id = 'portfolio-images'
     AND auth.role() = 'authenticated'
   );
   ```

---

## Frontend Configuration

### Step 5: Install Dependencies

1. Navigate to the frontend directory:

   ```bash
   cd /Users/rishfilet/Projects/portfolio-website-2025/frontend
   ```

2. Install dependencies (if not already done):
   ```bash
   pnpm install
   ```

### Step 6: Configure Environment Variables

1. Create a `.env.local` file in the `frontend` directory:

   ```bash
   cd /Users/rishfilet/Projects/portfolio-website-2025/frontend
   touch .env.local
   ```

2. Add your Supabase credentials:

   **For Self-Hosted (Docker) Setup:**

   Get your credentials by running:

   ```bash
   ~/supabase-[instance-name]/manage-supabase.sh credentials
   ```

   Then copy the values to `.env.local`:

   ```env
   # Supabase Configuration
   NEXT_PUBLIC_SUPABASE_URL=http://your-server:8000
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-from-credentials-file
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-from-credentials-file
   ```

   **For Cloud Setup:**

   Use the values from your Supabase dashboard (Settings → API):

   ```env
   # Supabase Configuration
   NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

3. **Important**: Never commit `.env.local` to git! It's already in `.gitignore`.

---

## Creating Admin User

### Step 7: Create Your Admin Account

Create an admin user to access the admin panel:

#### For Self-Hosted (Docker) Setup:

1. Access Supabase Studio at http://your-server-ip:3001
2. Login with Studio credentials (from credentials file)
3. Go to **Authentication** → **Users**
4. Click **"Add user"** → **"Create new user"**
5. Fill in:
   - **Email**: your-admin-email@example.com
   - **Password**: Choose a strong password
   - **Auto Confirm User**: ✅ Yes
6. Click **"Create user"**

**Security Note**: Since you're self-hosting, make sure to:

- Use a strong, unique password
- Consider setting up 2FA later
- Restrict network access to your Supabase instance
- Use HTTPS in production with a reverse proxy

#### For Cloud Setup:

1. In your Supabase dashboard, go to **Authentication** → **Users**
2. Click **"Add user"**
3. Choose **"Create new user"**
4. Fill in:
   - **Email**: your-admin-email@example.com
   - **Password**: Choose a strong password
   - **Auto Confirm User**: ✅ Yes
5. Click **"Create user"**

---

## Running the Application

### Step 8: Start the Development Server

1. Make sure you're in the frontend directory:

   ```bash
   cd /Users/rishfilet/Projects/portfolio-website-2025/frontend
   ```

2. Start the development server:

   ```bash
   pnpm dev
   ```

3. Open your browser to:
   - **Public site**: http://localhost:3000
   - **Admin panel**: http://localhost:3000/admin

### Step 9: Log In to Admin Panel

1. Navigate to http://localhost:3000/admin
2. You'll be redirected to the login page
3. Enter the admin credentials you created in Step 7
4. Click **"Sign In"**
5. You should now see the admin dashboard!

---

## Using the Admin Panel

### Admin Dashboard Overview

The admin panel has several sections accessible from the top navigation:

1. **Dashboard** (`/admin`)

   - Overview of your content statistics
   - Quick actions for common tasks

2. **Content** (`/admin/content`)

   - Manage landing page hero section
   - Update header, subheaders, description
   - Manage social links

3. **Projects** (`/admin/projects`)

   - View all projects
   - Publish/unpublish projects
   - Add new projects
   - Delete projects

4. **Blog** (`/admin/blog`)

   - View all blog posts
   - Publish/unpublish posts
   - Create new posts
   - Delete posts

5. **About** (`/admin/about`)

   - Manage about page sections (coming soon)

6. **Settings** (`/admin/settings`)
   - Configure site title and description
   - Set logo and favicon URLs
   - Customize color scheme

### Managing Landing Page Content

1. Go to **Content** in the admin panel
2. Edit the **Hero Section**:
   - **Header**: Your name
   - **Sub-headers**: Comma-separated rotating text (e.g., "Developer,Designer,Creator")
   - **Description**: Your bio/tagline
   - **Hero Image URL**: Optional background image
3. Click **"Save Landing Page"**
4. Refresh your public site to see changes

### Managing Social Links

1. In the **Content** section, scroll to **Social Links**
2. To add a new link:
   - **Display Name**: e.g., "GitHub"
   - **Icon Shortcode**: e.g., "github" (FontAwesome icon name without "fa-" prefix)
   - **Link URL**: Full URL to your profile
   - Click **"Add Link"**
3. To delete a link, click the **"Delete"** button next to it

### Creating Blog Posts

**Note**: The full blog post editor is not yet implemented. For now, you can add posts directly to the database:

1. In your Supabase dashboard, go to **Table Editor** → **blog_posts**
2. Click **"Insert row"**
3. Fill in:
   - **title**: Post title
   - **slug**: URL-friendly version (e.g., "my-first-post")
   - **post_content**: Full content (supports Markdown)
   - **post_summary**: Short summary
   - **is_published**: true/false
4. Click **"Save"**

### Creating Projects

**Note**: The full project editor is not yet implemented. For now, add projects directly to the database:

1. In your Supabase dashboard, go to **Table Editor** → **project_posts**
2. Click **"Insert row"**
3. Fill in:
   - **title**: Project name
   - **slug**: URL-friendly version
   - **short_description**: Brief description
   - **project_summary**: Longer description
   - **github_url**: Link to GitHub repo (optional)
   - **live_demo_url**: Link to live demo (optional)
   - **is_published**: true/false
   - **display_order**: Order on projects page (0, 1, 2, etc.)
4. Click **"Save"**

### Adding Project Images

1. First, upload your image to the `portfolio-images` bucket:

   - Go to **Storage** → **portfolio-images**
   - Click **"Upload file"**
   - Select your image
   - Copy the public URL

2. Add image to database:
   - Go to **Table Editor** → **project_post_images**
   - Click **"Insert row"**
   - Fill in:
     - **project_post_id**: The UUID of your project
     - **image_url**: The public URL from step 1
     - **is_main**: true (for the main/featured image)
     - **order_index**: 0
   - Click **"Save"**

### Customizing Site Settings

1. Go to **Settings** in the admin panel
2. Update **General Settings**:
   - Site title
   - Site description
   - Logo URL (upload to Storage first)
   - Favicon URL
3. Customize **Color Scheme**:
   - Use color pickers to adjust all theme colors
   - Or enter hex codes manually
4. Click **"Save All Settings"**
5. Refresh your public site to see the new colors

---

## Troubleshooting

### Issue: Can't Log In to Admin Panel

**Solutions:**

- Verify your admin user exists in Supabase → Authentication → Users
- Check that the user is confirmed (green checkmark)
- Try resetting the password in Supabase
- Check browser console for errors
- Verify your `.env.local` file has correct Supabase credentials

### Issue: Database Tables Don't Exist

**Solutions:**

- Re-run the migrations (see Step 3)
- Check for SQL errors in Supabase → Logs
- Verify you're connected to the correct project

### Issue: Images Not Uploading

**Solutions:**

- Check that the `portfolio-images` bucket exists
- Verify bucket is set to **Public**
- Check storage policies are correctly set
- Verify file size is under 5MB
- Check file type is an image (jpg, png, gif, webp)

### Issue: Changes Not Appearing on Public Site

**Solutions:**

- Hard refresh the page (Ctrl+Shift+R or Cmd+Shift+R)
- Check that content is marked as `is_published = true`
- Check that content is `is_active = true` (for About sections)
- Verify database queries are returning data (check browser console)
- Try restarting the dev server

### Issue: Environment Variables Not Working

**Solutions:**

- File must be named `.env.local` exactly
- Must be in the `frontend` directory
- Restart the dev server after creating/editing
- Variables starting with `NEXT_PUBLIC_` are visible in browser
- Never use service role key in client-side code

### Issue: RLS (Row Level Security) Errors

**Solutions:**

- Check that all RLS policies were created (see database migrations)
- For admin access, ensure user is authenticated
- For public access, ensure content is published/active
- Check Supabase logs for specific policy violations

### Docker-Specific Issues (Self-Hosted Only)

#### Issue: Containers Won't Start

**Solutions:**

```bash
# Check if ports are already in use
lsof -i :3001  # Studio
lsof -i :8000  # API
lsof -i :5432  # Database

# Check Docker logs
cd ~/supabase-[instance-name]/supabase/docker
docker-compose logs
```

#### Issue: Can't Connect to Database

**Solutions:**

- Verify containers are running: `docker-compose ps`
- Check firewall rules aren't blocking ports
- Verify credentials from credentials file
- For remote access, ensure ports are exposed in docker-compose.yml

#### Issue: Lost Credentials

**Solutions:**

```bash
# View credentials again
~/supabase-[instance-name]/manage-supabase.sh credentials
```

#### Issue: Need to Reset Everything

**Solutions:**

```bash
cd ~/supabase-[instance-name]/supabase/docker

# Stop and remove everything (WARNING: deletes all data!)
docker-compose down -v

# Start fresh
docker-compose up -d

# Re-run migrations
```

---

## Next Steps

### Recommended Improvements

1. **Add Content Editors**:

   - Implement rich text editor for blog posts
   - Create project form with image upload
   - Add About page management forms

2. **Image Management**:

   - Add image upload directly in admin forms
   - Create image gallery/media library
   - Add image optimization

3. **SEO**:

   - Add meta tags to all pages
   - Implement Open Graph tags
   - Create sitemap generation

4. **Analytics**:

   - Integrate Google Analytics or Plausible
   - Track page views in database
   - Add admin analytics dashboard

5. **Content Versioning**:
   - Implement content history viewing
   - Add ability to revert changes
   - Create draft/preview system

### Production Deployment

When ready to deploy:

1. **Prepare Database**:

   - Create production Supabase project
   - Run migrations on production database
   - Set up backups

2. **Configure Environment**:

   - Add production environment variables to your hosting platform
   - Use production Supabase credentials
   - Ensure service role key is kept secret

3. **Deploy Frontend**:

   - Push to Vercel, Netlify, or your preferred host
   - Configure build settings:
     - Build command: `pnpm build`
     - Output directory: `.next`
   - Add environment variables in hosting dashboard

4. **Security**:
   - Review all RLS policies
   - Limit admin user access
   - Set up 2FA for Supabase account
   - Monitor authentication logs

---

## Support

If you encounter issues not covered in this guide:

1. Check the Supabase documentation: https://supabase.com/docs
2. Review Next.js documentation: https://nextjs.org/docs
3. Check the project's `ADMIN_ARCHITECTURE.md` for technical details
4. Look at the database migration files for schema reference

---

## Summary

You now have a fully functional admin panel for managing your portfolio website! Here's what you can do:

## 📸 Image Management

The admin panel uses simple URL-based image management. You have several options:

### Option 1: External Image Hosting (Recommended)

Use free image hosting services:

- **Cloudinary** (https://cloudinary.com) - Free tier, CDN included
- **ImgBB** (https://imgbb.com) - Free, no account needed
- **GitHub** - Store in a public repo
- **Your own CDN**

**How to use:**

1. Upload image to hosting service
2. Copy the direct URL
3. Paste URL into admin panel fields (`logo_url`, `hero_image_url`, etc.)

Example: `https://res.cloudinary.com/your-account/image/upload/v1234567890/logo.png`

### Option 2: Next.js Public Folder

Store images in your frontend:

```bash
# Create images directory
mkdir -p frontend/public/images

# Add your images
cp my-logo.png frontend/public/images/

# Reference in admin panel as:
/images/my-logo.png
```

### Option 3: Supabase Storage (If Working)

If your Supabase Storage is configured:

1. Access Supabase Studio → Storage
2. Create bucket: `portfolio-images` (make it public)
3. Upload images
4. Use the generated URLs

**If Storage Bucket Creation Fails:**

Run the troubleshooting script on your Supabase server:

```bash
# On your server
cd /path/to/portfolio
./scripts/check-supabase-storage.sh
```

Common issues:

- Storage container not running
- Kong gateway misconfiguration
- Missing environment variables

**Workaround:** Use Options 1 or 2 above - they work without Supabase Storage!

---

## ✅ Feature Checklist

✅ Log in to the admin panel  
✅ Update landing page content  
✅ Manage social links  
✅ Add images via URLs (no bucket needed!)
✅ View and manage blog posts  
✅ View and manage projects  
✅ Customize site colors and branding  
✅ Publish/unpublish content

The system is designed to be extensible, so you can add more features as needed. All content is stored in Supabase and automatically synced to your public website.

Happy content managing! 🚀
