-- Fix Site Settings to be a Singleton Table
-- This ensures only one row can exist in site_settings

-- Step 1: Keep only the most recent row and delete the rest
DELETE FROM site_settings
WHERE id NOT IN (
  SELECT id 
  FROM site_settings 
  ORDER BY updated_at DESC 
  LIMIT 1
);

-- Step 2: Add a check constraint to ensure only one row can exist
ALTER TABLE site_settings 
ADD COLUMN IF NOT EXISTS singleton_guard BOOLEAN DEFAULT TRUE;

-- Create a unique constraint on singleton_guard
CREATE UNIQUE INDEX IF NOT EXISTS site_settings_singleton 
ON site_settings (singleton_guard);

-- Add a check constraint to ensure singleton_guard is always TRUE
ALTER TABLE site_settings 
ADD CONSTRAINT site_settings_singleton_check 
CHECK (singleton_guard = TRUE);

-- Ensure exactly one row exists (in case all were deleted)
INSERT INTO site_settings (site_title, site_description, singleton_guard)
SELECT 
  'Rishi Khan Portfolio', 
  'Creative Engineer & Full Stack Developer',
  TRUE
WHERE NOT EXISTS (SELECT 1 FROM site_settings);

-- Comment for documentation
COMMENT ON COLUMN site_settings.singleton_guard IS 'Ensures only one row can exist in this table (singleton pattern)';

