-- Enhanced Portfolio Schema
-- This migration adds portfolio-specific content types and admin features

-- Create site_settings table (singleton)
CREATE TABLE site_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  site_title VARCHAR(100) DEFAULT 'My Portfolio',
  site_description TEXT,
  logo_url TEXT,
  favicon_url TEXT,
  -- Brand Colors
  primary_color VARCHAR(7) DEFAULT '#059669',
  secondary_color VARCHAR(7) DEFAULT '#10b981',
  accent_color VARCHAR(7) DEFAULT '#34d399',
  -- Background Colors
  background_color VARCHAR(7) DEFAULT '#ffffff',
  secondary_background_color VARCHAR(7) DEFAULT '#f9fafb',
  -- Text Colors
  text_color VARCHAR(7) DEFAULT '#111827',
  secondary_text_color VARCHAR(7) DEFAULT '#6b7280',
  link_color VARCHAR(7) DEFAULT '#059669',
  -- UI Colors
  border_color VARCHAR(7) DEFAULT '#e5e7eb',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default site settings (singleton)
INSERT INTO site_settings (site_title, site_description) VALUES 
('Rishi Khan Portfolio', 'Creative Engineer & Full Stack Developer');

-- Enhance project_posts table with additional fields
ALTER TABLE project_posts ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE project_posts ADD COLUMN IF NOT EXISTS short_description TEXT;
ALTER TABLE project_posts ADD COLUMN IF NOT EXISTS github_url VARCHAR(500);
ALTER TABLE project_posts ADD COLUMN IF NOT EXISTS live_demo_url VARCHAR(500);
ALTER TABLE project_posts ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- Create about_ventures table (for entrepreneurial ventures)
CREATE TABLE about_ventures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name VARCHAR(255) NOT NULL,
  role VARCHAR(255),
  period VARCHAR(100), -- e.g., "2023 - Present"
  description TEXT,
  achievements JSONB DEFAULT '[]', -- Array of achievement strings
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create about_experiences table (for professional/consulting experience)
CREATE TABLE about_experiences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_type VARCHAR(50) NOT NULL CHECK (experience_type IN ('professional', 'consulting', 'freelance')),
  job_title VARCHAR(255) NOT NULL,
  company_name VARCHAR(255) NOT NULL,
  period VARCHAR(100), -- e.g., "2022 - Present"
  description TEXT,
  achievements JSONB DEFAULT '[]', -- Array of achievement strings
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create about_hobbies table
CREATE TABLE about_hobbies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  hobby_name VARCHAR(255) NOT NULL,
  icon_name VARCHAR(100), -- FontAwesome icon name (e.g., 'faBook')
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create about_values table (core values)
CREATE TABLE about_values (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  value_title VARCHAR(255) NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create content_history table for audit trail
CREATE TABLE content_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,
  action VARCHAR(20) NOT NULL CHECK (action IN ('created', 'updated', 'deleted')),
  changes JSONB,
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create storage bucket policies (to be run in Supabase dashboard)
-- Note: This is documented here but must be created via Supabase UI or API

-- Create indexes for performance
CREATE INDEX idx_about_ventures_active ON about_ventures(is_active);
CREATE INDEX idx_about_ventures_order ON about_ventures(display_order);
CREATE INDEX idx_about_experiences_type ON about_experiences(experience_type);
CREATE INDEX idx_about_experiences_active ON about_experiences(is_active);
CREATE INDEX idx_about_experiences_order ON about_experiences(display_order);
CREATE INDEX idx_about_hobbies_active ON about_hobbies(is_active);
CREATE INDEX idx_about_hobbies_order ON about_hobbies(display_order);
CREATE INDEX idx_about_values_active ON about_values(is_active);
CREATE INDEX idx_about_values_order ON about_values(display_order);
CREATE INDEX idx_content_history_table ON content_history(table_name);
CREATE INDEX idx_content_history_record ON content_history(record_id);
CREATE INDEX idx_project_posts_order ON project_posts(display_order);

-- Create updated_at triggers for new tables
CREATE TRIGGER update_site_settings_updated_at 
  BEFORE UPDATE ON site_settings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_about_ventures_updated_at 
  BEFORE UPDATE ON about_ventures 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_about_experiences_updated_at 
  BEFORE UPDATE ON about_experiences 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_about_hobbies_updated_at 
  BEFORE UPDATE ON about_hobbies 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_about_values_updated_at 
  BEFORE UPDATE ON about_values 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for About page

-- Entrepreneurial Ventures
INSERT INTO about_ventures (company_name, role, period, description, achievements, display_order) VALUES 
('TechStart Solutions', 'Founder & CEO', '2023 - Present', 
 'Founded and led a technology consulting firm specializing in sustainable software solutions for climate tech companies.',
 '["Secured $500K in seed funding for climate monitoring platform", "Built team of 12 engineers and designers", "Developed 3 proprietary software solutions"]',
 1),
('GreenTech Innovations', 'Co-founder', '2021 - 2023',
 'Co-founded a startup focused on renewable energy optimization and smart grid management systems.',
 '["Reduced energy consumption by 30% through smart grid implementations", "Developed AI-driven climate prediction models", "Partnerships with 5 major utility companies"]',
 2);

-- Professional Experiences
INSERT INTO about_experiences (experience_type, job_title, company_name, period, description, achievements, display_order) VALUES 
('consulting', 'Senior IT Consultant', 'Climate Solutions Inc.', '2022 - Present',
 'Leading development of climate monitoring and renewable energy optimization platforms for enterprise clients.',
 '["Reduced energy consumption by 30% through smart grid implementations", "Developed AI-driven climate prediction models", "Led team of 8 engineers on critical infrastructure projects"]',
 1),
('professional', 'Software Architect', 'Space Technology Corp', '2020 - 2022',
 'Designed and implemented satellite communication systems and ground station software for space missions.',
 '["Built fault-tolerant communication protocols for deep space missions", "Optimized data processing pipelines for 50% faster satellite imagery analysis", "Established software engineering best practices across organization"]',
 2),
('freelance', 'Full Stack Developer', 'Renewable Energy Systems', '2018 - 2020',
 'Developed smart grid management systems and energy distribution platforms for renewable energy companies.',
 '["Created real-time monitoring dashboards for 100+ wind farms", "Implemented predictive maintenance algorithms reducing downtime by 25%", "Integrated IoT sensors for comprehensive energy network visibility"]',
 3);

-- Hobbies
INSERT INTO about_hobbies (hobby_name, icon_name, description, display_order) VALUES 
('Reading', 'faBook', 'Avid reader of science fiction, technology books, and philosophy. Currently exploring climate science literature and space exploration history.', 1),
('Hiking', 'faHiking', 'Love exploring nature trails and mountains. Completed several multi-day treks and always planning the next adventure.', 2),
('Music', 'faMusic', 'Playing guitar and piano. Enjoy composing ambient electronic music and exploring different musical genres.', 3),
('Photography', 'faCamera', 'Passionate about landscape and astrophotography. Capturing the beauty of nature and the cosmos through the lens.', 4),
('Gaming', 'faGamepad', 'Enjoy strategy games and indie titles. Particularly interested in games that explore environmental themes and space exploration.', 5),
('Digital Art', 'faPalette', 'Creating digital illustrations and concept art. Focus on sci-fi themes, environmental concepts, and futuristic cityscapes.', 6);

-- Core Values
INSERT INTO about_values (value_title, description, display_order) VALUES 
('Sustainability First', 'Every solution I build considers environmental impact and long-term sustainability.', 1),
('Innovation Driven', 'Constantly exploring cutting-edge technologies to solve complex challenges.', 2),
('Collaborative Approach', 'Building strong partnerships with clients and teams to achieve shared goals.', 3),
('Technical Excellence', 'Committed to writing clean, efficient, and maintainable code.', 4);

-- Enable Row Level Security (RLS)
ALTER TABLE site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE about_ventures ENABLE ROW LEVEL SECURITY;
ALTER TABLE about_experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE about_hobbies ENABLE ROW LEVEL SECURITY;
ALTER TABLE about_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE landing_page_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE technologies ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public read access
CREATE POLICY "Public can view active content"
  ON about_ventures FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can view active experiences"
  ON about_experiences FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can view active hobbies"
  ON about_hobbies FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can view active values"
  ON about_values FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can view site settings"
  ON site_settings FOR SELECT
  USING (true);

CREATE POLICY "Public can view landing page"
  ON landing_page_content FOR SELECT
  USING (true);

CREATE POLICY "Public can view published blogs"
  ON blog_posts FOR SELECT
  USING (is_published = true);

CREATE POLICY "Public can view published projects"
  ON project_posts FOR SELECT
  USING (is_published = true);

CREATE POLICY "Public can view social links"
  ON social_links FOR SELECT
  USING (true);

CREATE POLICY "Public can view tags"
  ON tags FOR SELECT
  USING (true);

CREATE POLICY "Public can view technologies"
  ON technologies FOR SELECT
  USING (true);

-- RLS Policies for authenticated admin users (full access)
CREATE POLICY "Authenticated users have full access to ventures"
  ON about_ventures FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to experiences"
  ON about_experiences FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to hobbies"
  ON about_hobbies FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to values"
  ON about_values FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to site settings"
  ON site_settings FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to landing page"
  ON landing_page_content FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to blog posts"
  ON blog_posts FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to project posts"
  ON project_posts FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to social links"
  ON social_links FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to tags"
  ON tags FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users have full access to technologies"
  ON technologies FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view content history"
  ON content_history FOR SELECT
  USING (auth.role() = 'authenticated');

-- Comments for documentation
COMMENT ON TABLE site_settings IS 'Singleton table for global site configuration and theme settings';
COMMENT ON TABLE about_ventures IS 'Entrepreneurial ventures for About page';
COMMENT ON TABLE about_experiences IS 'Professional, consulting, and freelance experiences for About page';
COMMENT ON TABLE about_hobbies IS 'Hobbies and interests for About page';
COMMENT ON TABLE about_values IS 'Core values for About page';
COMMENT ON TABLE content_history IS 'Audit trail for all content changes';


