-- Fix Landing Page Content to be a Singleton Table
-- This ensures only one row can exist in landing_page_content

-- Step 1: Keep only the most recent row and delete the rest
DELETE FROM landing_page_content
WHERE id NOT IN (
  SELECT id 
  FROM landing_page_content 
  ORDER BY updated_at DESC 
  LIMIT 1
);

-- Step 2: Add a check constraint to ensure only one row can exist
-- We'll use a trick: add a column with a constant value and make it unique
ALTER TABLE landing_page_content 
ADD COLUMN IF NOT EXISTS singleton_guard BOOLEAN DEFAULT TRUE;

-- Create a unique constraint on singleton_guard
-- This ensures only one row with singleton_guard = TRUE can exist
CREATE UNIQUE INDEX IF NOT EXISTS landing_page_content_singleton 
ON landing_page_content (singleton_guard);

-- Add a check constraint to ensure singleton_guard is always TRUE
ALTER TABLE landing_page_content 
ADD CONSTRAINT landing_page_content_singleton_check 
CHECK (singleton_guard = TRUE);

-- Ensure exactly one row exists (in case all were deleted)
INSERT INTO landing_page_content (header, description, sub_headers, singleton_guard)
SELECT 
  'Welcome to My Portfolio', 
  'I am a passionate developer who loves building amazing web applications.', 
  'Full Stack Developer,UI/UX Designer,Problem Solver',
  TRUE
WHERE NOT EXISTS (SELECT 1 FROM landing_page_content);

-- Comment for documentation
COMMENT ON COLUMN landing_page_content.singleton_guard IS 'Ensures only one row can exist in this table (singleton pattern)';

