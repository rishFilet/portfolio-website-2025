-- Enable RLS on themes table
ALTER TABLE themes ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read themes (public access for theme loading)
CREATE POLICY "Allow public read access to themes"
  ON themes
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Allow authenticated users to read all themes (including inactive ones)
CREATE POLICY "Allow authenticated users to read all themes"
  ON themes
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to update themes
CREATE POLICY "Allow authenticated users to update themes"
  ON themes
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to insert themes
CREATE POLICY "Allow authenticated users to insert themes"
  ON themes
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to delete themes
CREATE POLICY "Allow authenticated users to delete themes"
  ON themes
  FOR DELETE
  TO authenticated
  USING (true);


