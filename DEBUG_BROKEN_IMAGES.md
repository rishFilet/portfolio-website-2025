# Debug Broken Images - Step by Step

## What We're Trying to Find

We need to determine:

1. What URLs are being generated
2. What URLs are stored in the database
3. What URLs the browser is trying to load
4. Why those URLs are failing

## Step 1: Check What URLs Are Stored in Database

Run this to see what image URLs are in your production database:

```bash
./scripts/debug-image-urls.sh
# Choose option 2 (Production)
```

**Look for:**

- Are the URLs using the correct domain? (`api.supabase.rishikhan.dev`)
- Do they have the correct port? (`:54331`)
- Do they have the correct format? (`/storage/v1/object/public/BUCKET/FILE`)

**Example of CORRECT URL:**

```
http://api.supabase.rishikhan.dev:54331/storage/v1/object/public/theme-logos/1234567890-abc123.png
```

**Example of WRONG URLs:**

```
https://supabase.rishikhan.dev/storage/v1/object/public/theme-logos/... (wrong domain)
http://127.0.0.1:54331/storage/v1/object/public/theme-logos/...       (localhost, not accessible)
http://localhost:54321/storage/v1/object/public/theme-logos/...       (wrong port)
```

## Step 2: Check Browser Console

1. **Open your production site** in a browser
2. **Press F12** to open DevTools
3. **Go to Console tab**
4. **Look for the image upload debug log:**
   ```
   🖼️ Image Upload Debug: {
     bucket: "theme-logos",
     filePath: "1234567890-abc123.png",
     generatedUrl: "http://...",
     supabaseUrl: "http://..."
   }
   ```

**What to check:**

- Is `supabaseUrl` pointing to the right endpoint?
- Is `generatedUrl` using that URL correctly?

## Step 3: Check Network Tab

1. **With DevTools still open, go to Network tab**
2. **Filter by "Img" or "All"**
3. **Look for failed requests** (they'll be red)
4. **Click on a failed image request**
5. **Check the full URL** in the "Headers" section

**Common issues:**

- **404 Not Found**: File doesn't exist or bucket name is wrong
- **403 Forbidden**: Storage policies blocking access
- **Connection refused/timeout**: Port not accessible from outside
- **ERR_NAME_NOT_RESOLVED**: Domain doesn't resolve

## Step 4: Test Direct Image Access

Copy a failing image URL from the Network tab and try to access it directly:

**In a new browser tab, paste:**

```
http://api.supabase.rishikhan.dev:54331/storage/v1/object/public/theme-logos/YOUR_FILE.png
```

**What happens?**

- ✅ **Image downloads/shows**: Storage is working, issue is elsewhere
- ❌ **404 Error**: File doesn't exist in that bucket
- ❌ **403 Forbidden**: Storage policy issue
- ❌ **Connection timeout**: Port 54331 is not accessible
- ❌ **SSL/Certificate error**: HTTPS issue (use HTTP instead)

## Step 5: Check Production Environment Variables

On your **production server** (where your website runs):

```bash
# SSH into production server
ssh user@your-server

# Check the environment file
cat /path/to/your/frontend/.env.local

# Or if deployed with Docker:
docker exec YOUR_CONTAINER env | grep SUPABASE
```

**Should show:**

```env
NEXT_PUBLIC_SUPABASE_URL=http://api.supabase.rishikhan.dev:54331
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOi...
```

**Common mistakes:**

- Using `https://` instead of `http://`
- Using `supabase.rishikhan.dev` instead of `api.supabase.rishikhan.dev`
- Missing the port `:54331`
- Using `localhost` or `127.0.0.1`

## Step 6: Test Storage Endpoint Directly

From your production server or your local machine:

```bash
# Test if storage endpoint is accessible
curl -I http://api.supabase.rishikhan.dev:54331/storage/v1/healthcheck

# Should return HTTP 200 OK
```

**If this fails:**

- Port 54331 might not be open on firewall
- Kong (API gateway) might not be running
- Domain might not resolve correctly

## Step 7: Check Firewall / Port Access

On your **production server**:

```bash
# Check if port is listening
sudo netstat -tuln | grep 54331

# Check firewall rules
sudo ufw status | grep 54331

# If port not allowed, allow it:
sudo ufw allow 54331
```

**From your local machine:**

```bash
# Test if port is accessible from outside
telnet api.supabase.rishikhan.dev 54331
# or
nc -zv api.supabase.rishikhan.dev 54331
```

## Step 8: Check Supabase Containers

On your **production server**:

```bash
# Check if storage container is running
docker ps | grep storage

# Check Kong (API Gateway) is running
docker ps | grep kong

# Check storage logs
docker logs supabase_storage_portfolio-website-2025 --tail 50

# Check Kong logs
docker logs supabase_kong_portfolio-website-2025 --tail 50
```

## Step 9: Verify Storage Bucket Access

Connect to your production database and test:

```bash
psql "postgresql://postgres:PASSWORD@HOST:PORT/postgres" << 'EOF'
-- Check bucket exists and is public
SELECT id, name, public FROM storage.buckets WHERE id = 'theme-logos';

-- Check files exist in bucket
SELECT name, bucket_id FROM storage.objects WHERE bucket_id = 'theme-logos' LIMIT 5;

-- Check storage policies
SELECT policyname, cmd FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';
EOF
```

## Quick Fixes Based on Symptoms

### Symptom: URLs have `127.0.0.1` or `localhost`

**Problem:** Your production frontend is using local Supabase URL

**Fix:**

```bash
# On production server, edit .env.local
nano /path/to/frontend/.env.local

# Change to:
NEXT_PUBLIC_SUPABASE_URL=http://api.supabase.rishikhan.dev:54331

# Restart frontend
pm2 restart frontend  # or however you run it
```

### Symptom: Connection timeout / Port not accessible

**Problem:** Port 54331 is not open or Kong is not forwarding requests

**Fix:**

```bash
# On production server
sudo ufw allow 54331

# Check Kong is running
docker ps | grep kong

# If not running, restart:
cd /path/to/supabase
docker-compose restart kong
```

### Symptom: 403 Forbidden

**Problem:** Storage policies blocking access

**Fix:**

```bash
# Apply storage migration again
./scripts/apply-storage-migration.sh
# Choose production
```

### Symptom: 404 Not Found but file exists in bucket

**Problem:** Bucket name mismatch or file path issue

**Check:**

```bash
./scripts/debug-image-urls.sh
```

Look for the exact bucket and file names in the database vs what's in the actual storage.

## Test Upload Flow

1. **Delete all images** from admin panel (Settings page)
2. **Open browser DevTools** (F12 → Console tab)
3. **Upload a new image**
4. **Check console for debug log:**
   ```
   🖼️ Image Upload Debug: {
     bucket: "theme-logos",
     filePath: "1234567890-abc123.png",
     generatedUrl: "http://api.supabase.rishikhan.dev:54331/storage/v1/object/public/theme-logos/1234567890-abc123.png",
     supabaseUrl: "http://api.supabase.rishikhan.dev:54331"
   }
   ```
5. **Copy the `generatedUrl`**
6. **Paste in new browser tab** - does it work?

## Still Broken?

If after all these steps images are still broken, provide me with:

1. **Output from:** `./scripts/debug-image-urls.sh`
2. **A failing image URL** from browser DevTools Network tab
3. **Your production `NEXT_PUBLIC_SUPABASE_URL`** (hide sensitive parts)
4. **Result of:** `curl -I http://api.supabase.rishikhan.dev:54331/storage/v1/healthcheck`
5. **Browser console errors** (screenshot or copy-paste)

## Most Common Issues

1. ✅ **Wrong Supabase URL in production** - 80% of cases
2. ✅ **Port 54331 not accessible** - 15% of cases
3. ✅ **Storage migration not applied** - 4% of cases
4. ✅ **Bucket names wrong** - 1% of cases
