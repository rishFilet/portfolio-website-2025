# Cookieless Client Fix - Public Page Data Fetching

## The Problem

Public pages (home, blog, projects) were showing hardcoded fallback content instead of database content for unauthenticated users.

**Root Cause:**

- Public pages used `getLandingPageData()` from `queries.ts`
- This function uses `createServerSupabaseClient()` from `@supabase/ssr` which depends on authentication cookies
- When users aren't logged in → No cookies → Query fails → Returns `null`
- Pages fall back to hardcoded defaults: "Rishi Khan", "Creative Engineer & Full Stack Developer", etc.

## The Solution

Created a **cookieless Supabase client** for public pages that works regardless of authentication state.

### Files Created

**`frontend/src/lib/supabase/queries-public.ts`**

- Cookieless query functions for public data
- Uses `createClient()` from `@supabase/supabase-js` (not the SSR package)
- Configured with `persistSession: false` to avoid auth dependencies

### Files Modified

**`frontend/src/app/page.tsx`**

- Changed: `getLandingPageData()` → `getPublicLandingPageData()`
- Changed: `getLatestBlogPost()` → `getPublicLatestBlogPost()`

**`frontend/src/app/blog/page.tsx`**

- Changed: `getBlogPosts()` → `getPublicBlogPosts()`

**`frontend/src/app/projects/page.tsx`**

- Changed: `getProjectPosts()` → `getPublicProjectPosts()`

### Files Kept Unchanged

**`frontend/src/lib/supabase/queries.ts`**

- Keep for admin pages (they need cookie-based auth)

**`frontend/src/lib/supabase/server.ts`**

- Keep for admin authentication

**All admin pages**

- Continue using cookie-based client for authenticated operations

## How It Works

### Before (Cookie-Dependent)

```typescript
// queries.ts
const supabase = await createServerSupabaseClient(); // Needs cookies
```

**Result:** Unauthenticated users → Failed queries → Fallback content

### After (Cookieless)

```typescript
// queries-public.ts
const supabase = createClient(url, key, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
  },
});
```

**Result:** All users → Successful queries → Database content ✅

## Testing

### Local

```bash
cd frontend
npm run dev
# Visit http://localhost:3004
# Should see database content (not "Rishi Khan")
```

### Production

```bash
# After deployment
curl -s https://rishikhan.dev | grep -o '<h1[^>]*>.*</h1>'
# Should show your actual database H1, not "Rishi Khan"
```

### Verification

1. ✅ Unauthenticated users see database content
2. ✅ New visitors (no cookies) see database content
3. ✅ Incognito mode shows database content
4. ✅ Content same for all users regardless of auth state

## Key Benefits

1. **Consistent behavior** - All users see the same content
2. **No auth dependency** - Public data doesn't require authentication
3. **Works immediately** - No cache warming or delays
4. **Simple solution** - Just use the right client for the job

## Other Fixes Applied

These were real issues fixed during development:

1. **Image Optimization** (`next.config.ts`)

   - Added `api.supabase.rishikhan.dev` to `remotePatterns`
   - Fixes: "is not an allowed pattern" errors

2. **Database Schema** (migrations)

   - Singleton constraints for `landing_page_content` and `site_settings`
   - Storage bucket policies for public image access
   - RLS policies for authenticated users

3. **Query Updates** (`queries.ts`)
   - Changed `.single()` to `.limit(1)` for singleton tables
   - Fixes queries when multiple rows exist

## Summary

The issue was NOT caching - it was **authentication-dependent queries** for public data.

**Solution:** Use cookieless client (`queries-public.ts`) for public pages, keep cookie-based client (`queries.ts`) for admin pages.

Simple, clean, correct. ✅
