# Production Deployment Fix - Truncated Anon Key

## The Problem

Public pages (home, blog, projects) were showing hardcoded fallback content on production, but working correctly locally.

**Root Cause:**
The `NEXT_PUBLIC_SUPABASE_ANON_KEY` environment variable in Netlify was **truncated**, containing only 1 part of the JWT instead of the required 3 parts.

**Error:**
```json
{
  "code": "PGRST301",
  "message": "Expected 3 parts in JWT; got 1"
}
```

## The Solution

### 1. Fix Environment Variable in Netlify

Updated `NEXT_PUBLIC_SUPABASE_ANON_KEY` in Netlify with the complete JWT:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

### 2. Architectural Improvement - Cookieless Client

While fixing the anon key issue, we also improved the architecture by creating a cookieless Supabase client for public pages.

**Created:** `frontend/src/lib/supabase/queries-public.ts`
- Uses `createClient()` from `@supabase/supabase-js` (not SSR package)
- Configured with `persistSession: false` to avoid auth dependencies
- Better separation of concerns: public queries vs authenticated queries

**Updated Pages:**
- `frontend/src/app/page.tsx` → uses `getPublicLandingPageData()`
- `frontend/src/app/blog/page.tsx` → uses `getPublicBlogPosts()`
- `frontend/src/app/projects/page.tsx` → uses `getPublicProjectPosts()`

## Why Both Fixes Matter

1. **Truncated Anon Key** - The immediate issue that broke all Supabase queries
2. **Cookieless Client** - Better architecture that ensures public data fetching doesn't depend on authentication state

## Testing

### Verify Supabase Connection
```bash
curl https://rishikhan.dev/api/debug-queries | jq .
```

Should show successful queries with data.

### Verify Landing Page Content
```bash
curl -s https://rishikhan.dev | grep -o '<h1[^>]*>.*</h1>'
```

Should show database content, not fallback content.

## Key Learnings

1. **Environment Variables:** Always verify that long values (like JWTs) aren't truncated when copying to deployment platforms
2. **Git Submodules:** Remember to commit changes in both the submodule AND update the parent repo's submodule reference
3. **Debug Endpoints:** Creating temporary debug endpoints (`/api/debug-queries`) can quickly diagnose production issues

## Files Changed

### Code (Kept)
- `frontend/src/lib/supabase/queries-public.ts` (new)
- `frontend/src/app/page.tsx` (updated to use public queries)
- `frontend/src/app/blog/page.tsx` (updated to use public queries)
- `frontend/src/app/projects/page.tsx` (updated to use public queries)

### Code (Removed)
- `frontend/src/app/api/debug-queries/route.ts` (temporary debug endpoint)

### Other Fixes Applied
- **Image Optimization** (`next.config.ts`): Added `api.supabase.rishikhan.dev` to `remotePatterns`
- **Database Schema** (migrations): Singleton constraints for `landing_page_content` and `site_settings`
- **Favicon** (`icon.tsx`): Changed `.single()` to `.order().limit(1)` for singleton tables

## Summary

**Problem:** Truncated anon key in Netlify → All Supabase queries failed → Fallback content displayed

**Solution:** 
1. Fixed truncated anon key in Netlify environment variables
2. Implemented cookieless client for better architecture

**Result:** ✅ Production site now shows database content correctly
