-- Enable storage
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- Create storage buckets for images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('images', 'images', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif']),
  ('hero-images', 'hero-images', true, 10485760, ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif']),
  ('logos', 'logos', true, 2097152, ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/svg+xml']),
  ('favicons', 'favicons', true, 1048576, ARRAY['image/png', 'image/x-icon', 'image/vnd.microsoft.icon']),
  ('theme-logos', 'theme-logos', true, 2097152, ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/svg+xml']),
  ('theme-hero-images', 'theme-hero-images', true, 10485760, ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif'])
ON CONFLICT (id) DO NOTHING;

-- Storage policies for public access
-- Allow public to read all images
CREATE POLICY "Public can view images" ON storage.objects
  FOR SELECT
  USING (bucket_id IN ('images', 'hero-images', 'logos', 'favicons', 'theme-logos', 'theme-hero-images'));

-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload images" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id IN ('images', 'hero-images', 'logos', 'favicons', 'theme-logos', 'theme-hero-images'));

-- Allow authenticated users to update their images
CREATE POLICY "Authenticated users can update images" ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id IN ('images', 'hero-images', 'logos', 'favicons', 'theme-logos', 'theme-hero-images'))
  WITH CHECK (bucket_id IN ('images', 'hero-images', 'logos', 'favicons', 'theme-logos', 'theme-hero-images'));

-- Allow authenticated users to delete images
CREATE POLICY "Authenticated users can delete images" ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id IN ('images', 'hero-images', 'logos', 'favicons', 'theme-logos', 'theme-hero-images'));

