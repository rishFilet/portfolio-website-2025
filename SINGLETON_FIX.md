# Singleton Table Fix - Landing Page Content

## Problem

The `landing_page_content` and `site_settings` tables were allowing multiple rows to be created, which caused issues:

1. **Saving didn't persist**: Each save created a NEW row instead of updating the existing one
2. **Loading failed**: The `.single()` query failed when multiple rows existed
3. **Data inconsistency**: Multiple rows with different content existed in the database

## Root Cause

The tables were designed as "singleton" tables (only one row should exist), but there was no database constraint enforcing this. The admin page code used `.single()` which:

- **Fails if 0 rows exist** → Inserts a new row
- **Fails if 2+ rows exist** → Can't determine which row to use, returns null
- When `landingPage` was null, the save function created a **new** row instead of updating

This created a cycle: failed load → null state → insert new row → multiple rows → failed load...

## Solution

### 1. Database Changes

Applied singleton constraints using a clever pattern:

```sql
-- Add a column that's always TRUE
ALTER TABLE landing_page_content
ADD COLUMN singleton_guard BOOLEAN DEFAULT TRUE;

-- Make it UNIQUE (only one TRUE value can exist)
CREATE UNIQUE INDEX landing_page_content_singleton
ON landing_page_content (singleton_guard);

-- Ensure it's always TRUE
ALTER TABLE landing_page_content
ADD CONSTRAINT landing_page_content_singleton_check
CHECK (singleton_guard = TRUE);
```

This guarantees only **one row** can ever exist in these tables.

### 2. Code Changes

Updated both admin and frontend code to use `.limit(1)` instead of `.single()`:

**Before:**

```typescript
const { data } = await supabase
  .from("landing_page_content")
  .select("*")
  .single(); // Fails if 0 or 2+ rows
```

**After:**

```typescript
const { data } = await supabase
  .from("landing_page_content")
  .select("*")
  .order("updated_at", { ascending: false })
  .limit(1); // Always returns 0 or 1 row, never fails

const landingPageData = data && data.length > 0 ? data[0] : null;
```

### 3. Cleanup

The migrations automatically:

- Delete all duplicate rows (keeping the most recent)
- Add the singleton constraint
- Ensure exactly one row exists

## Files Changed

### Database Migrations

- `supabase/migrations/20241201000006_fix_landing_page_singleton.sql`
- `supabase/migrations/20241201000007_fix_site_settings_singleton.sql`

### Frontend Code

- `frontend/src/app/admin/content/page.tsx` - Admin page load/save logic
- `frontend/src/lib/supabase/queries.ts` - Frontend data fetching

### Scripts

- `scripts/apply-production-migration.sh` - Updated to apply singleton fixes
- `scripts/fix-singleton-tables.sh` - New script to apply fixes to any database
- `scripts/debug-landing-page.sh` - Debug tool to check table state

## Applying to Production

### Option 1: Run the full migration script

```bash
./scripts/apply-production-migration.sh
```

### Option 2: Apply only the singleton fixes

```bash
./scripts/fix-singleton-tables.sh
# Choose option 2 (Production)
# Enter your production database credentials
```

### Option 3: Manual SQL (if you prefer)

```bash
# Connect to your production database
psql "postgresql://user:pass@host:port/db"

# Run the migrations manually
\i supabase/migrations/20241201000006_fix_landing_page_singleton.sql
\i supabase/migrations/20241201000007_fix_site_settings_singleton.sql
```

## Verification

After applying, you can verify with:

```bash
./scripts/debug-landing-page.sh
```

This will show:

- ✅ Number of rows (should be 1)
- ✅ Content of the row
- ✅ Constraints applied

## Testing

1. **Local testing** (already applied):

   - Go to `http://localhost:3004/admin/content`
   - Edit the hero section
   - Click "Save Landing Page"
   - Refresh the page → Your changes should still be there
   - Go to the main site → Changes should be visible

2. **Production testing**:
   - Apply the fix: `./scripts/fix-singleton-tables.sh`
   - Go to your production admin panel
   - Edit the hero section
   - Save and refresh → Changes should persist

## Benefits

✅ **Saves now persist** - Updates existing row instead of creating new ones
✅ **Loads always work** - Uses `.limit(1)` instead of `.single()`
✅ **Data consistency** - Only one source of truth
✅ **Database enforced** - Impossible to create duplicate rows
✅ **Automatic cleanup** - Migration removes any existing duplicates

## Technical Details

### Why This Pattern Works

The `singleton_guard` column with a UNIQUE constraint ensures only one row can have the value `TRUE`. Since we:

1. Set the default to `TRUE`
2. Add a CHECK constraint to prevent it being `FALSE`
3. Make it UNIQUE

...the database will **reject** any attempt to insert a second row with `ERROR: duplicate key value violates unique constraint`.

This is more robust than application-level checks because:

- It's enforced at the database level
- Prevents race conditions
- Works regardless of which code/tool accesses the database
- Survives code changes

### Same Pattern Applied To

- `landing_page_content` - Hero section data
- `site_settings` - Global site configuration

Both are "singleton" tables that should only ever have one row.
