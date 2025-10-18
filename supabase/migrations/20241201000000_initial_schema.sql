-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tags table
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create technologies table
CREATE TABLE technologies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create blog posts table
CREATE TABLE blog_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  post_content TEXT NOT NULL,
  post_summary TEXT,
  likes INTEGER DEFAULT 0,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create blog post images table
CREATE TABLE blog_post_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blog_post_id UUID REFERENCES blog_posts(id) ON DELETE CASCADE,
  image_url VARCHAR(500) NOT NULL,
  image_name VARCHAR(255),
  is_main BOOLEAN DEFAULT false,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create blog post tags junction table
CREATE TABLE blog_post_tags (
  blog_post_id UUID REFERENCES blog_posts(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (blog_post_id, tag_id)
);

-- Create project posts table
CREATE TABLE project_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  project_summary TEXT,
  project_url VARCHAR(500),
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create project post images table
CREATE TABLE project_post_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_post_id UUID REFERENCES project_posts(id) ON DELETE CASCADE,
  image_url VARCHAR(500) NOT NULL,
  image_name VARCHAR(255),
  is_main BOOLEAN DEFAULT false,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create project post tags junction table
CREATE TABLE project_post_tags (
  project_post_id UUID REFERENCES project_posts(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (project_post_id, tag_id)
);

-- Create project post technologies junction table
CREATE TABLE project_post_technologies (
  project_post_id UUID REFERENCES project_posts(id) ON DELETE CASCADE,
  technology_id UUID REFERENCES technologies(id) ON DELETE CASCADE,
  PRIMARY KEY (project_post_id, technology_id)
);

-- Create landing page content table
CREATE TABLE landing_page_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  header VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  sub_headers TEXT, -- Comma-separated list
  hero_image_url VARCHAR(500),
  hero_image_name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create about page content table
CREATE TABLE about_page_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  profile_image_url VARCHAR(500),
  profile_image_name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create social links table
CREATE TABLE social_links (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  display_name VARCHAR(255) NOT NULL,
  icon_shortcode VARCHAR(100) NOT NULL,
  link VARCHAR(500) NOT NULL,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_blog_posts_slug ON blog_posts(slug);
CREATE INDEX idx_blog_posts_published ON blog_posts(is_published);
CREATE INDEX idx_project_posts_slug ON project_posts(slug);
CREATE INDEX idx_project_posts_published ON project_posts(is_published);
CREATE INDEX idx_blog_post_images_blog_post_id ON blog_post_images(blog_post_id);
CREATE INDEX idx_project_post_images_project_post_id ON project_post_images(project_post_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON blog_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_project_posts_updated_at BEFORE UPDATE ON project_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_landing_page_content_updated_at BEFORE UPDATE ON landing_page_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_about_page_content_updated_at BEFORE UPDATE ON about_page_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_social_links_updated_at BEFORE UPDATE ON social_links FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert initial data
INSERT INTO landing_page_content (header, description, sub_headers) VALUES 
('Welcome to My Portfolio', 'I am a passionate developer who loves building amazing web applications.', 'Full Stack Developer,UI/UX Designer,Problem Solver');

INSERT INTO about_page_content (title, content) VALUES 
('About Me', 'I am a dedicated developer with a passion for creating beautiful and functional web applications. I love working with modern technologies and solving complex problems.');

-- Insert some sample tags
INSERT INTO tags (name) VALUES 
('React'), ('Node.js'), ('TypeScript'), ('Next.js'), ('PostgreSQL'), ('Supabase');

-- Insert some sample technologies
INSERT INTO technologies (name) VALUES 
('React'), ('Node.js'), ('TypeScript'), ('Next.js'), ('PostgreSQL'), ('Supabase'), ('Tailwind CSS'), ('Docker');

-- Insert sample social links
INSERT INTO social_links (display_name, icon_shortcode, link, order_index) VALUES 
('GitHub', 'github', 'https://github.com/yourusername', 1),
('LinkedIn', 'linkedin', 'https://linkedin.com/in/yourusername', 2),
('Twitter', 'twitter', 'https://twitter.com/yourusername', 3); 