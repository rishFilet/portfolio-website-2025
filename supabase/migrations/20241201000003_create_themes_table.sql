-- Create themes table
CREATE TABLE themes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  unique_name VARCHAR(50) NOT NULL UNIQUE,
  font_awesome_icon VARCHAR(100) NOT NULL,
  primary_color_hex VARCHAR(7) NOT NULL,
  secondary_color_hex VARCHAR(7) NOT NULL,
  font_color_hex VARCHAR(7) NOT NULL,
  accent_color_hex VARCHAR(7) NOT NULL,
  logo_url VARCHAR(500),
  logo_name VARCHAR(255),
  hero_image_url VARCHAR(500),
  hero_image_name VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on unique_name for faster lookups
CREATE INDEX idx_themes_unique_name ON themes(unique_name);

-- Insert default light theme
INSERT INTO themes (
  unique_name,
  font_awesome_icon,
  primary_color_hex,
  secondary_color_hex,
  font_color_hex,
  accent_color_hex,
  is_active
) VALUES (
  'light',
  'fas fa-sun',
  '#ffffff',
  '#000000',
  '#000000',
  '#2bb1a5',
  true
);

-- Insert default dark theme
INSERT INTO themes (
  unique_name,
  font_awesome_icon,
  primary_color_hex,
  secondary_color_hex,
  font_color_hex,
  accent_color_hex,
  is_active
) VALUES (
  'dark',
  'fas fa-moon',
  '#1a1a1a',
  '#ffffff',
  '#ffffff',
  '#2bb1a5',
  true
);

