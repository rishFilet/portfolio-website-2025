# Admin Page Architecture Guide

> **Purpose**: This document provides detailed instructions for building, understanding, and extending the admin panel for the Caterbots landing page. It explains how content flows from the database to the website and how to add new content types.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Technology Stack](#technology-stack)
3. [Database Architecture](#database-architecture)
4. [Content Flow Architecture](#content-flow-architecture)
5. [Admin Panel Components](#admin-panel-components)
6. [How to Analyze Existing Content](#how-to-analyze-existing-content)
7. [How to Add New Content Types](#how-to-add-new-content-types)
8. [Complete Implementation Example](#complete-implementation-example)
9. [Security & Authentication](#security--authentication)
10. [Deployment & Revalidation](#deployment--revalidation)

---

## System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERACTS                          │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              ADMIN PANEL (Protected)                    │   │
│  │  - Content Management Dashboard                         │   │
│  │  - Settings Editor                                      │   │
│  │  - Image Uploader                                       │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     ↓                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         SUPABASE DATABASE (PostgreSQL)                  │   │
│  │  Tables:                                                │   │
│  │  - landing_content (sections, content blocks)           │   │
│  │  - site_settings (theme, colors, logos)                 │   │
│  │  - content_history (audit trail)                        │   │
│  │  Storage:                                               │   │
│  │  - caterbots-images (image uploads)                     │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     ↓                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            PUBLIC LANDING PAGE                          │   │
│  │  - Server-side rendering (Next.js)                      │   │
│  │  - Fetches active content from database                 │   │
│  │  - Displays dynamic sections                            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Key Features

1. **Dynamic Content Management**: Admin can update website content without code changes
2. **Section-Based Architecture**: Content organized by sections (hero, features, CTA, etc.)
3. **Theme Customization**: Full control over colors, logos, and styling
4. **Image Management**: Upload and manage images via Supabase Storage
5. **Real-time Updates**: Changes reflect immediately via revalidation
6. **Audit Trail**: Complete history of content changes
7. **Row-Level Security**: Database-level access control

---

## Technology Stack

### Frontend
- **Next.js 14** (App Router): React framework with server-side rendering
- **React 18**: UI library with hooks
- **TypeScript**: Type safety
- **Tailwind CSS**: Utility-first styling
- **shadcn/ui**: Component library (Button, Input, Table, etc.)
- **React Hook Form**: Form state management
- **Zod**: Schema validation

### Backend
- **Supabase**: Backend-as-a-Service
  - PostgreSQL database
  - Authentication
  - Storage (S3-compatible)
  - Row-Level Security (RLS)

### Key Libraries
- `@supabase/supabase-js`: Supabase client
- `lucide-react`: Icon library
- `@hookform/resolvers`: Form validation
- `next/image`: Optimized images

---

## Database Architecture

### Tables Overview

#### 1. `landing_content` Table

**Purpose**: Stores all content blocks for the landing page sections.

**Schema**:
```sql
CREATE TABLE landing_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section VARCHAR(50) NOT NULL CHECK (section IN ('hero', 'features', 'cta', 'footer', 'trust_indicators', 'about_us')),
  title TEXT,
  subtitle TEXT,
  description TEXT,
  image_url TEXT,
  cta_text VARCHAR(100),
  cta_link TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);
```

**Field Descriptions**:
- `section`: Which part of the page (hero, features, etc.)
- `title`: Main heading text
- `subtitle`: Secondary heading
- `description`: Body text/description
- `image_url`: URL to image (from Supabase Storage or external)
- `cta_text`: Call-to-action button text
- `cta_link`: Where the CTA button links to
- `display_order`: Order of content within section (0, 1, 2...)
- `is_active`: Whether to show on public page
- `metadata`: Flexible JSON field for section-specific data
  - Examples: `secondary_buttons`, `team_members`, `description_blocks`

**Indexes**:
```sql
CREATE INDEX idx_landing_content_section ON landing_content(section);
CREATE INDEX idx_landing_content_active ON landing_content(is_active);
CREATE INDEX idx_landing_content_order ON landing_content(display_order);
```

**Row-Level Security (RLS)**:
```sql
-- Public can view active content
CREATE POLICY "Public can view active content"
  ON landing_content FOR SELECT
  USING (is_active = true);

-- Authenticated users can do everything
CREATE POLICY "Authenticated users have full access"
  ON landing_content FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
```

#### 2. `site_settings` Table

**Purpose**: Stores global site configuration (theme colors, logos, metadata).

**Schema**:
```sql
CREATE TABLE site_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  logo_url TEXT,
  favicon_url TEXT,
  site_title VARCHAR(100) DEFAULT 'Caterbots',
  site_description TEXT,
  -- Brand Colors
  primary_color VARCHAR(7) DEFAULT '#059669',
  secondary_color VARCHAR(7) DEFAULT '#10b981',
  accent_color VARCHAR(7) DEFAULT '#34d399',
  -- Button Colors
  button_color VARCHAR(7) DEFAULT '#059669',
  button_hover_color VARCHAR(7) DEFAULT '#047857',
  -- Background Colors
  background_color VARCHAR(7) DEFAULT '#ffffff',
  secondary_background_color VARCHAR(7) DEFAULT '#f9fafb',
  -- Text Colors
  text_color VARCHAR(7) DEFAULT '#111827',
  secondary_text_color VARCHAR(7) DEFAULT '#6b7280',
  link_color VARCHAR(7) DEFAULT '#059669',
  -- UI Colors
  border_color VARCHAR(7) DEFAULT '#e5e7eb',
  -- Hero-specific Colors
  hero_h1_color VARCHAR(7) DEFAULT '#ffffff',
  hero_h2_color VARCHAR(7) DEFAULT '#ffffff',
  hero_subtext_color VARCHAR(7) DEFAULT '#f3f4f6',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);
```

**Note**: This is a singleton table (only one row exists). All updates modify this single row.

#### 3. `content_history` Table

**Purpose**: Audit trail for all content changes.

**Schema**:
```sql
CREATE TABLE content_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID REFERENCES landing_content(id) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL CHECK (action IN ('created', 'updated', 'deleted')),
  changes JSONB,
  changed_by UUID REFERENCES auth.users(id),
  changed_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Automatic Logging**: Triggers automatically log all INSERT, UPDATE, DELETE operations.

#### 4. Storage Bucket: `caterbots-images`

**Purpose**: Stores uploaded images (logos, hero images, team photos, etc.).

**Configuration**:
- Public bucket (images accessible via public URL)
- Authenticated users can upload
- File size limit: 5MB
- Accepted formats: JPG, PNG, GIF, WebP

---

## Content Flow Architecture

### Write Path (Admin → Database → Public)

```
┌──────────────────────────────────────────────────────────────┐
│ 1. ADMIN EDITS CONTENT                                       │
│    ↓                                                          │
│    User opens ContentEditor component                        │
│    File: components/admin/ContentEditor.tsx                  │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ 2. FORM SUBMISSION                                           │
│    ↓                                                          │
│    React Hook Form validates data (Zod schema)               │
│    File: schemas/content.schema.ts                           │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ 3. DATABASE WRITE                                            │
│    ↓                                                          │
│    Supabase client sends INSERT/UPDATE                       │
│    RLS policies verify authentication                        │
│    Trigger logs change to content_history                    │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ 4. REVALIDATION TRIGGER                                      │
│    ↓                                                          │
│    POST /api/revalidate with path: "/"                       │
│    File: app/api/revalidate/route.ts                         │
│    Clears Next.js cache for home page                        │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ 5. NEXT USER VISIT                                           │
│    ↓                                                          │
│    Server renders page with fresh data                       │
│    File: app/(public)/page.tsx                               │
│    Fetches active content from database                      │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Read Path (Public Page Render)

**File: `app/(public)/page.tsx`**
```typescript
export const revalidate = 10; // Revalidate every 10 seconds

export default async function Home() {
  // 1. Fetch active content grouped by section
  const dynamicContent = await getPublicActiveContent();
  
  // 2. Fetch site settings (colors, logo, etc.)
  const siteSettings = await getPublicSiteSettings();
  
  // 3. Render sections with dynamic data
  return (
    <main>
      <Header logoUrl={siteSettings?.logo_url} colors={siteSettings} />
      <Hero content={dynamicContent.hero?.[0]} colors={siteSettings} />
      <Features content={dynamicContent.features} colors={siteSettings} />
      {/* ... more sections */}
    </main>
  );
}
```

**Content Fetching (`lib/content-public.ts`)**:
```typescript
export async function getPublicActiveContent() {
  const supabase = await createServerSupabaseClient();
  
  // Fetch all active content, ordered by section and display_order
  const { data, error } = await supabase
    .from("landing_content")
    .select("*")
    .eq("is_active", true)
    .order("section", { ascending: true })
    .order("display_order", { ascending: true });
  
  // Group content by section
  return groupBySection(data); // { hero: [...], features: [...], cta: [...] }
}
```

---

## Admin Panel Components

### 1. Admin Dashboard (`app/admin/page.tsx`)

**Purpose**: Main entry point for content management.

**Features**:
- Statistics cards (total content, active content, recent changes)
- Content list table
- Create new content button

**Data Fetching**:
```typescript
const supabase = await createServerSupabaseClient();

// Fetch all content (including inactive)
const { data: allContent } = await supabase
  .from("landing_content")
  .select("*")
  .order("section", { ascending: true })
  .order("display_order", { ascending: true });
```

### 2. Content List (`components/admin/ContentList.tsx`)

**Purpose**: Display table of all content blocks with edit/delete actions.

**Features**:
- Table view with section, title, status, order
- Edit button (opens ContentEditor)
- Delete button (with confirmation)
- Create new content button
- Real-time refresh after changes

**Client-Side Actions**:
```typescript
// Delete content
const handleDelete = async (id: string) => {
  await supabase.from("landing_content").delete().eq("id", id);
  await fetch("/api/revalidate", { method: "POST", body: JSON.stringify({ path: "/" }) });
  await refreshContent();
};
```

### 3. Content Editor (`components/admin/ContentEditor.tsx`)

**Purpose**: Form for creating/editing content blocks.

**Features**:
- **Dynamic fields based on section**:
  - Hero: title, subtitle, description, image, CTA
  - Features: title, description, image
  - CTA: title, description, CTA + secondary buttons
  - About Us: title, subtitle, team members, description blocks
  - Trust Indicators: company name, logo
  - Footer: title, tagline, footer text, logo

- **Section-specific metadata**:
  - `secondary_buttons` (CTA section): Additional action buttons
  - `team_members` (About Us): Array of team member objects
  - `description_blocks` (About Us): Array of content blocks

- **Image upload**: Drag-and-drop or click to upload
- **Preview**: Button to preview site in new tab
- **Active/Inactive toggle**: Control visibility on public page

**Form Validation**:
```typescript
// File: schemas/content.schema.ts
export const contentSchema = z.object({
  section: z.enum(["hero", "features", "cta", "footer", "trust_indicators", "about_us"]),
  title: z.string().min(1, "Title is required"),
  subtitle: z.string().optional(),
  description: z.string().optional(),
  image_url: z.string().optional(),
  cta_text: z.string().optional(),
  cta_link: z.string().optional(),
  display_order: z.number().int().min(0),
  is_active: z.boolean(),
  metadata: z.record(z.any()).optional(),
});
```

**Submit Handler**:
```typescript
const onSubmit = async (data: ContentSchema) => {
  const contentData = {
    ...data,
    image_url: imageUrl || null,
    metadata: {
      ...data.metadata,
      secondary_buttons: selectedSection === "cta" ? secondaryButtons : undefined,
      team_members: selectedSection === "about_us" ? teamMembers : undefined,
      description_blocks: selectedSection === "about_us" ? descriptionBlocks : undefined,
    },
  };

  if (isNew) {
    await supabase.from("landing_content").insert([contentData]);
  } else {
    await supabase.from("landing_content").update(contentData).eq("id", content!.id);
  }

  // Trigger revalidation
  await fetch("/api/revalidate", { method: "POST", body: JSON.stringify({ path: "/" }) });
  
  onClose();
};
```

### 4. Settings Form (`components/admin/SettingsForm.tsx`)

**Purpose**: Edit global site settings (theme colors, logos).

**Features**:
- Logo upload with preview
- Favicon upload (optional, defaults to logo)
- Site title and description
- Color pickers for all theme colors:
  - Brand colors (primary, secondary, accent)
  - Button colors (normal, hover)
  - Background colors (primary, secondary)
  - Text colors (primary, secondary, link)
  - UI colors (border)
  - Hero-specific colors (H1, H2, subtext)
- Live color preview

**Save Handler**:
```typescript
const handleSave = async () => {
  const updateData = {
    logo_url: logoUrl || null,
    favicon_url: faviconUrl || logoUrl || null,
    site_title: siteTitle,
    site_description: siteDescription,
    primary_color: primaryColor,
    // ... all color fields
  };

  // Update singleton row
  await supabase.from("site_settings").update(updateData).eq("id", initialSettings.id);
  
  // Trigger revalidation
  await fetch("/api/revalidate", { method: "POST", body: JSON.stringify({ path: "/" }) });
};
```

### 5. Image Uploader (`components/admin/ImageUploader.tsx`)

**Purpose**: Upload images to Supabase Storage or use external URLs.

**Features**:
- Drag-and-drop upload
- Click to upload
- Manual URL input
- File validation (type, size)
- Preview uploaded image
- Remove image button

**Upload Handler**:
```typescript
const processFile = async (file: File) => {
  // Validate file type and size
  if (!file.type.startsWith("image/")) throw new Error("Invalid file type");
  if (file.size > 5 * 1024 * 1024) throw new Error("File too large");

  // Generate unique filename
  const timestamp = Date.now();
  const fileExt = file.name.split(".").pop();
  const fileName = `${timestamp}-${Math.random().toString(36).substring(2, 9)}.${fileExt}`;

  // Upload to Supabase Storage
  const { data, error } = await supabase.storage
    .from("caterbots-images")
    .upload(fileName, file, { cacheControl: "3600", upsert: false });

  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from("caterbots-images")
    .getPublicUrl(fileName);

  onImageUploaded(publicUrl);
};
```

---

## How to Analyze Existing Content

### Step 1: Examine Current Sections

**Check Public Page**: `app/(public)/page.tsx`

Look at what sections are currently rendered:
```typescript
<Hero content={dynamicContent.hero?.[0]} colors={siteSettings} />
<TrustIndicators content={dynamicContent.trust_indicators} colors={siteSettings} />
<Features content={dynamicContent.features} colors={siteSettings} />
<AboutUs content={dynamicContent.about_us?.[0]} colors={siteSettings} />
<FinalCTA content={dynamicContent.cta?.[0]} />
<Footer content={dynamicContent.footer?.[0]} />
```

**Key Observations**:
- Some sections take a single content object: `hero?.[0]`, `cta?.[0]`, `about_us?.[0]`
- Some sections take an array: `features`, `trust_indicators`
- All sections receive `colors` (site settings)

### Step 2: Examine Section Components

**Example: Hero Section** (`components/landing/Hero.tsx`)

```typescript
interface HeroProps {
  content?: LandingContent;  // Single content block
  colors?: SiteSettings | null;
}

export function Hero({ content, colors }: HeroProps) {
  // Extract fields with fallbacks
  const title = content?.title || "Default Title";
  const subtitle = content?.subtitle || "Default Subtitle";
  const description = content?.description || "Default Description";
  const ctaText = content?.cta_text || "Get Started";
  const ctaLink = content?.cta_link || "#";
  const bgImage = content?.image_url || "https://default-image-url.com";

  return (
    <section className="relative h-screen">
      {/* Background */}
      <div style={{ backgroundImage: `url("${bgImage}")` }} />
      
      {/* Content */}
      <h1 style={{ color: colors?.hero_h1_color || "#ffffff" }}>
        {title}
      </h1>
      <p style={{ color: colors?.hero_h2_color || "#ffffff" }}>
        {subtitle}
      </p>
      <p style={{ color: colors?.hero_subtext_color || "#f3f4f6" }}>
        {description}
      </p>
      <Button onClick={() => openWindow(ctaLink)}>
        {ctaText}
      </Button>
    </section>
  );
}
```

**Fields Used by Hero**:
- `title` → Main headline
- `subtitle` → Subheadline
- `description` → Supporting text
- `image_url` → Background image
- `cta_text` → Button text
- `cta_link` → Button destination
- `metadata` → Not used (but available for future extensions)

**Example: Features Section** (`components/landing/Features.tsx`)

```typescript
interface FeaturesProps {
  content?: LandingContent[];  // Array of content blocks
  colors?: SiteSettings | null;
}

export function Features({ content, colors }: FeaturesProps) {
  // Map over content array
  return (
    <section>
      {content?.map((feature) => (
        <div key={feature.id}>
          <img src={feature.image_url} alt={feature.title} />
          <h3>{feature.title}</h3>
          <p>{feature.description}</p>
        </div>
      ))}
    </section>
  );
}
```

**Fields Used by Features**:
- `title` → Feature name
- `description` → Feature explanation
- `image_url` → Feature icon/image
- Other fields ignored

### Step 3: Check Database Types

**File: `types/content.types.ts`**

```typescript
export interface LandingContent {
  id: string;
  section: "hero" | "features" | "cta" | "footer" | "trust_indicators" | "about_us";
  title: string | null;
  subtitle: string | null;
  description: string | null;
  image_url: string | null;
  cta_text: string | null;
  cta_link: string | null;
  display_order: number;
  is_active: boolean;
  metadata: Record<string, any>;  // Flexible JSON field
  created_at: string;
  updated_at: string;
  created_by: string | null;
  updated_by: string | null;
}
```

**File: `types/database.types.ts`**

Contains Supabase-generated types matching the database schema.

### Step 4: Identify Content Patterns

After analyzing the codebase, you'll find these patterns:

| Section | Type | Fields Used | Metadata Used |
|---------|------|-------------|---------------|
| Hero | Single | title, subtitle, description, image_url, cta_text, cta_link | None |
| Features | Array | title, description, image_url | None |
| Trust Indicators | Array | title (company name), image_url (logo) | None |
| About Us | Single | title, subtitle | team_members, description_blocks |
| CTA | Single | title, subtitle, description, cta_text, cta_link | secondary_buttons |
| Footer | Single | title, subtitle, description, image_url | None |

---

## How to Add New Content Types

### Process Overview

When a user wants to add a new content type (e.g., "Testimonials", "Portfolio", "Blog Posts"), follow these steps:

### Step 1: Interview the User

**Questions to Ask**:

1. **What do you want to call this new section?**
   - Example: "Testimonials", "Portfolio", "Team Gallery"

2. **Where should it appear on the page?**
   - Before/after which existing section?

3. **How many instances of this content will there be?**
   - Single item (like Hero) or multiple items (like Features)?

4. **What information needs to be stored for each instance?**
   - Name/title?
   - Description/body text?
   - Image?
   - Link/URL?
   - Author/source?
   - Date?
   - Rating/stars?
   - Any other custom fields?

5. **Do you need any special functionality?**
   - Carousel/slider?
   - Filter/search?
   - Pagination?
   - Category/tags?

### Step 2: Design the Data Structure

**Example: Adding "Testimonials" Section**

Based on user responses:
- Section name: `testimonials`
- Multiple testimonials (array)
- Fields needed:
  - Quote text (description)
  - Customer name (title)
  - Customer title/company (subtitle)
  - Customer photo (image_url)
  - Rating (metadata.rating)
  - Date (metadata.date)

### Step 3: Update Database Schema

**File: `supabase/migrations/XXX_add_testimonials_section.sql`**

```sql
-- 1. Add 'testimonials' to the section enum
ALTER TABLE landing_content 
DROP CONSTRAINT IF EXISTS landing_content_section_check;

ALTER TABLE landing_content 
ADD CONSTRAINT landing_content_section_check 
CHECK (section IN ('hero', 'features', 'cta', 'footer', 'trust_indicators', 'about_us', 'testimonials'));

-- 2. Insert default testimonials data (optional)
INSERT INTO landing_content (section, title, subtitle, description, image_url, display_order, is_active, metadata)
VALUES 
  ('testimonials', 'John Smith', 'CEO, Acme Catering', 'This service has transformed our business! We get 50% more orders.', 'https://i.pravatar.cc/150?img=1', 0, true, '{"rating": 5, "date": "2024-01-15"}'),
  ('testimonials', 'Jane Doe', 'Owner, Tasty Treats', 'Never miss a call again. Highly recommend!', 'https://i.pravatar.cc/150?img=2', 1, true, '{"rating": 5, "date": "2024-01-20"}');
```

**Deploy Migration**:
```bash
supabase db push
```

### Step 4: Update TypeScript Types

**File: `types/content.types.ts`**

```typescript
export interface LandingContent {
  id: string;
  section: "hero" | "features" | "cta" | "footer" | "trust_indicators" | "about_us" | "testimonials"; // Add "testimonials"
  // ... rest of fields
}

export interface ContentFormData {
  section: "hero" | "features" | "cta" | "footer" | "trust_indicators" | "about_us" | "testimonials"; // Add "testimonials"
  // ... rest of fields
}
```

**File: `types/database.types.ts`**

Update the generated types to match (or regenerate from Supabase):

```typescript
export interface Database {
  public: {
    Tables: {
      landing_content: {
        Row: {
          section: "hero" | "features" | "cta" | "footer" | "trust_indicators" | "about_us" | "testimonials";
          // ... rest
        };
        // ... Insert, Update types
      };
    };
  };
}
```

### Step 5: Create React Component

**File: `components/landing/Testimonials.tsx`**

```typescript
"use client";

import { Star } from "lucide-react";
import Image from "next/image";
import type { LandingContent } from "@/types/content.types";
import type { SiteSettings } from "@/types/settings.types";

interface TestimonialsProps {
  content?: LandingContent[];  // Array of testimonials
  colors?: SiteSettings | null;
}

export function Testimonials({ content, colors }: TestimonialsProps) {
  // If no content, show static fallback
  if (!content || content.length === 0) {
    return (
      <section className="py-24 px-4" style={{ backgroundColor: colors?.secondary_background_color || "#f9fafb" }}>
        <div className="max-w-7xl mx-auto">
          <h2 className="text-4xl font-bold text-center mb-12" style={{ color: colors?.text_color || "#111827" }}>
            What Our Customers Say
          </h2>
          <p className="text-center" style={{ color: colors?.secondary_text_color || "#6b7280" }}>
            No testimonials yet. Add some in the admin panel!
          </p>
        </div>
      </section>
    );
  }

  return (
    <section className="py-24 px-4" style={{ backgroundColor: colors?.secondary_background_color || "#f9fafb" }}>
      <div className="max-w-7xl mx-auto">
        <h2 className="text-4xl font-bold text-center mb-12" style={{ color: colors?.text_color || "#111827" }}>
          What Our Customers Say
        </h2>
        
        <div className="grid md:grid-cols-3 gap-8">
          {content.map((testimonial) => (
            <div 
              key={testimonial.id} 
              className="p-6 rounded-lg shadow-md"
              style={{ backgroundColor: colors?.background_color || "#ffffff" }}
            >
              {/* Rating Stars */}
              {testimonial.metadata?.rating && (
                <div className="flex mb-4">
                  {[...Array(testimonial.metadata.rating)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 fill-yellow-400 text-yellow-400" />
                  ))}
                </div>
              )}
              
              {/* Quote */}
              <p 
                className="text-lg mb-6 italic"
                style={{ color: colors?.text_color || "#111827" }}
              >
                "{testimonial.description}"
              </p>
              
              {/* Customer Info */}
              <div className="flex items-center">
                {testimonial.image_url && (
                  <Image 
                    src={testimonial.image_url} 
                    alt={testimonial.title || "Customer"} 
                    width={48} 
                    height={48} 
                    className="rounded-full mr-4" 
                  />
                )}
                <div>
                  <p 
                    className="font-semibold"
                    style={{ color: colors?.text_color || "#111827" }}
                  >
                    {testimonial.title}
                  </p>
                  <p 
                    className="text-sm"
                    style={{ color: colors?.secondary_text_color || "#6b7280" }}
                  >
                    {testimonial.subtitle}
                  </p>
                </div>
              </div>
              
              {/* Date */}
              {testimonial.metadata?.date && (
                <p 
                  className="text-xs mt-4"
                  style={{ color: colors?.secondary_text_color || "#6b7280" }}
                >
                  {new Date(testimonial.metadata.date).toLocaleDateString()}
                </p>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

### Step 6: Add to Public Page

**File: `app/(public)/page.tsx`**

```typescript
import { Testimonials } from "@/components/landing/Testimonials";

export default async function Home() {
  const dynamicContent = await getPublicActiveContent();
  const siteSettings = await getPublicSiteSettings();

  return (
    <main>
      <Header logoUrl={siteSettings?.logo_url} colors={siteSettings} />
      <Hero content={dynamicContent.hero?.[0]} colors={siteSettings} />
      <TrustIndicators content={dynamicContent.trust_indicators} colors={siteSettings} />
      {/* ... other sections */}
      
      {/* ADD NEW SECTION HERE */}
      <Testimonials content={dynamicContent.testimonials} colors={siteSettings} />
      
      <FAQ colors={siteSettings} />
      <FinalCTA content={dynamicContent.cta?.[0]} />
      <Footer content={dynamicContent.footer?.[0]} />
    </main>
  );
}
```

### Step 7: Update Content Editor

**File: `components/admin/ContentEditor.tsx`**

Add section configuration:

```typescript
// Add to sectionConfig object
const sectionConfig = {
  // ... existing sections
  
  testimonials: {
    title: "Testimonials Section",
    fields: {
      title: { label: "Customer Name", placeholder: "John Smith", required: true },
      subtitle: { label: "Customer Title/Company", placeholder: "CEO, Acme Catering", show: true },
      description: { 
        label: "Testimonial Quote", 
        placeholder: "This service has transformed our business!", 
        show: true,
        required: true 
      },
      image: { label: "Customer Photo", show: true },
      cta: { show: false },
    },
  },
};
```

Add to section dropdown:

```typescript
<Select id="section" {...register("section")} disabled={loading}>
  <option value="hero">Hero</option>
  <option value="features">Features</option>
  <option value="trust_indicators">Trust Indicators</option>
  <option value="about_us">About Us</option>
  <option value="testimonials">Testimonials</option> {/* ADD THIS */}
  <option value="cta">Call to Action</option>
  <option value="footer">Footer</option>
</Select>
```

Add metadata fields for rating and date:

```typescript
{/* Testimonials-specific metadata */}
{selectedSection === "testimonials" && (
  <div className="space-y-4 p-4 border-2 border-purple-200 rounded-lg bg-purple-50">
    <Label className="text-lg font-semibold text-purple-900">Testimonial Details</Label>
    
    {/* Rating */}
    <div className="space-y-2">
      <Label>Rating (1-5 stars)</Label>
      <Input
        type="number"
        min="1"
        max="5"
        value={metadata.rating || 5}
        onChange={(e) => setMetadata({ ...metadata, rating: parseInt(e.target.value) })}
      />
    </div>
    
    {/* Date */}
    <div className="space-y-2">
      <Label>Date</Label>
      <Input
        type="date"
        value={metadata.date || ""}
        onChange={(e) => setMetadata({ ...metadata, date: e.target.value })}
      />
    </div>
  </div>
)}
```

Update submit handler to include metadata:

```typescript
const onSubmit = async (data: ContentSchema) => {
  const contentData = {
    ...data,
    image_url: imageUrl || null,
    metadata: {
      ...data.metadata,
      rating: selectedSection === "testimonials" ? metadata.rating : undefined,
      date: selectedSection === "testimonials" ? metadata.date : undefined,
      // ... other section-specific metadata
    },
  };
  
  // ... rest of submit logic
};
```

### Step 8: Update Schema Validation

**File: `schemas/content.schema.ts`**

```typescript
export const contentSchema = z.object({
  section: z.enum([
    "hero", 
    "features", 
    "cta", 
    "footer", 
    "trust_indicators", 
    "about_us", 
    "testimonials" // ADD THIS
  ]),
  title: z.string().min(1, "Title is required"),
  subtitle: z.string().optional(),
  description: z.string().optional(),
  image_url: z.string().optional(),
  cta_text: z.string().optional(),
  cta_link: z.string().optional(),
  display_order: z.number().int().min(0),
  is_active: z.boolean(),
  metadata: z.record(z.any()).optional(),
});
```

### Step 9: Test the New Section

1. **Deploy database migration**:
   ```bash
   supabase db push
   ```

2. **Restart Next.js dev server**:
   ```bash
   npm run dev
   ```

3. **Log into admin panel**:
   - Navigate to `/admin`
   - Click "Add Content"
   - Select "Testimonials" from section dropdown
   - Fill in customer name, title, quote, upload photo
   - Set rating and date in metadata fields
   - Save

4. **View on public page**:
   - Navigate to `/`
   - Scroll to testimonials section
   - Verify content displays correctly

5. **Test editing**:
   - Go back to admin
   - Edit the testimonial
   - Change quote text
   - Save and verify changes on public page

---

## Complete Implementation Example

### Example: Adding "Portfolio" Section

Let's walk through a complete example of adding a portfolio/case studies section.

#### User Requirements
- **Section Name**: Portfolio
- **Type**: Multiple items (array)
- **Fields**:
  - Project title
  - Client name
  - Project description
  - Before/after images
  - Project date
  - Industry/category
  - Results/metrics

#### Step-by-Step Implementation

**1. Create Migration**

`supabase/migrations/XXX_add_portfolio_section.sql`:
```sql
-- Add 'portfolio' to section enum
ALTER TABLE landing_content 
DROP CONSTRAINT IF EXISTS landing_content_section_check;

ALTER TABLE landing_content 
ADD CONSTRAINT landing_content_section_check 
CHECK (section IN (
  'hero', 'features', 'cta', 'footer', 
  'trust_indicators', 'about_us', 'portfolio'
));

-- Insert sample portfolio item
INSERT INTO landing_content (
  section, 
  title, 
  subtitle, 
  description, 
  image_url, 
  display_order, 
  is_active, 
  metadata
)
VALUES (
  'portfolio',
  'Acme Catering Website Redesign',
  'Acme Catering Co.',
  'Complete website redesign and branding refresh for Toronto-based catering company.',
  'https://example.com/portfolio-1.jpg',
  0,
  true,
  '{
    "before_image": "https://example.com/before-1.jpg",
    "after_image": "https://example.com/after-1.jpg",
    "date": "2024-01-15",
    "industry": "Food & Beverage",
    "results": ["50% increase in online orders", "70% faster load times", "95% customer satisfaction"]
  }'
);
```

**2. Update Types**

`types/content.types.ts`:
```typescript
export interface LandingContent {
  id: string;
  section: 
    | "hero" 
    | "features" 
    | "cta" 
    | "footer" 
    | "trust_indicators" 
    | "about_us" 
    | "portfolio"; // ADD THIS
  // ... rest unchanged
}

// Add interface for portfolio metadata
export interface PortfolioMetadata {
  before_image?: string;
  after_image?: string;
  date?: string;
  industry?: string;
  results?: string[];
}
```

**3. Create Component**

`components/landing/Portfolio.tsx`:
```typescript
"use client";

import { useState } from "react";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ChevronLeft, ChevronRight, CheckCircle } from "lucide-react";
import type { LandingContent } from "@/types/content.types";
import type { SiteSettings } from "@/types/settings.types";

interface PortfolioProps {
  content?: LandingContent[];
  colors?: SiteSettings | null;
}

export function Portfolio({ content, colors }: PortfolioProps) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [showBefore, setShowBefore] = useState(true);

  if (!content || content.length === 0) {
    return null; // Or show placeholder
  }

  const currentProject = content[currentIndex];
  const metadata = currentProject.metadata as { 
    before_image?: string; 
    after_image?: string;
    date?: string;
    industry?: string;
    results?: string[];
  };

  const nextProject = () => {
    setCurrentIndex((prev) => (prev + 1) % content.length);
    setShowBefore(true);
  };

  const prevProject = () => {
    setCurrentIndex((prev) => (prev - 1 + content.length) % content.length);
    setShowBefore(true);
  };

  return (
    <section 
      className="py-24 px-4"
      style={{ backgroundColor: colors?.background_color || "#ffffff" }}
    >
      <div className="max-w-7xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-12">
          <h2 
            className="text-4xl font-bold mb-4"
            style={{ color: colors?.text_color || "#111827" }}
          >
            Our Work
          </h2>
          <p 
            className="text-lg"
            style={{ color: colors?.secondary_text_color || "#6b7280" }}
          >
            Case studies and success stories from our clients
          </p>
        </div>

        {/* Portfolio Item */}
        <div className="grid md:grid-cols-2 gap-12 items-center">
          {/* Image Side */}
          <div className="relative">
            {/* Before/After Toggle */}
            {metadata.before_image && metadata.after_image && (
              <div className="mb-4 flex justify-center">
                <div className="inline-flex rounded-lg border p-1">
                  <Button
                    variant={showBefore ? "default" : "ghost"}
                    size="sm"
                    onClick={() => setShowBefore(true)}
                  >
                    Before
                  </Button>
                  <Button
                    variant={!showBefore ? "default" : "ghost"}
                    size="sm"
                    onClick={() => setShowBefore(false)}
                  >
                    After
                  </Button>
                </div>
              </div>
            )}

            {/* Image */}
            <div className="relative h-96 rounded-lg overflow-hidden shadow-xl">
              <Image
                src={
                  showBefore && metadata.before_image 
                    ? metadata.before_image 
                    : metadata.after_image || currentProject.image_url || ""
                }
                alt={currentProject.title || "Portfolio item"}
                fill
                className="object-cover"
              />
            </div>

            {/* Navigation */}
            {content.length > 1 && (
              <div className="flex justify-between mt-4">
                <Button
                  variant="outline"
                  size="icon"
                  onClick={prevProject}
                >
                  <ChevronLeft className="h-4 w-4" />
                </Button>
                <span 
                  className="self-center"
                  style={{ color: colors?.secondary_text_color || "#6b7280" }}
                >
                  {currentIndex + 1} / {content.length}
                </span>
                <Button
                  variant="outline"
                  size="icon"
                  onClick={nextProject}
                >
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            )}
          </div>

          {/* Content Side */}
          <div>
            {/* Industry Badge */}
            {metadata.industry && (
              <Badge 
                className="mb-4"
                style={{ 
                  backgroundColor: colors?.accent_color || "#34d399",
                  color: colors?.text_color || "#111827"
                }}
              >
                {metadata.industry}
              </Badge>
            )}

            {/* Title */}
            <h3 
              className="text-3xl font-bold mb-2"
              style={{ color: colors?.text_color || "#111827" }}
            >
              {currentProject.title}
            </h3>

            {/* Client */}
            <p 
              className="text-lg mb-4"
              style={{ color: colors?.secondary_text_color || "#6b7280" }}
            >
              {currentProject.subtitle}
            </p>

            {/* Description */}
            <p 
              className="mb-6"
              style={{ color: colors?.text_color || "#111827" }}
            >
              {currentProject.description}
            </p>

            {/* Results */}
            {metadata.results && metadata.results.length > 0 && (
              <div className="mb-6">
                <h4 
                  className="font-semibold mb-3"
                  style={{ color: colors?.text_color || "#111827" }}
                >
                  Results:
                </h4>
                <ul className="space-y-2">
                  {metadata.results.map((result: string, index: number) => (
                    <li key={index} className="flex items-start">
                      <CheckCircle 
                        className="w-5 h-5 mr-2 flex-shrink-0 mt-0.5"
                        style={{ color: colors?.primary_color || "#059669" }}
                      />
                      <span style={{ color: colors?.text_color || "#111827" }}>
                        {result}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Date */}
            {metadata.date && (
              <p 
                className="text-sm"
                style={{ color: colors?.secondary_text_color || "#6b7280" }}
              >
                Completed: {new Date(metadata.date).toLocaleDateString('en-US', { 
                  year: 'numeric', 
                  month: 'long' 
                })}
              </p>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
```

**4. Add to Public Page**

`app/(public)/page.tsx`:
```typescript
import { Portfolio } from "@/components/landing/Portfolio";

export default async function Home() {
  const dynamicContent = await getPublicActiveContent();
  const siteSettings = await getPublicSiteSettings();

  return (
    <main>
      {/* ... other sections */}
      <Portfolio content={dynamicContent.portfolio} colors={siteSettings} />
      {/* ... more sections */}
    </main>
  );
}
```

**5. Update Content Editor**

`components/admin/ContentEditor.tsx`:

Add section config:
```typescript
const sectionConfig = {
  // ... other sections
  
  portfolio: {
    title: "Portfolio Section",
    fields: {
      title: { label: "Project Title", placeholder: "Website Redesign", required: true },
      subtitle: { label: "Client Name", placeholder: "Acme Catering Co.", show: true },
      description: { 
        label: "Project Description", 
        placeholder: "Complete redesign of website and branding", 
        show: true 
      },
      image: { label: "After Image (Main)", show: true },
      cta: { show: false },
    },
  },
};
```

Add metadata fields:
```typescript
{selectedSection === "portfolio" && (
  <div className="space-y-4 p-4 border-2 border-blue-200 rounded-lg bg-blue-50">
    <Label className="text-lg font-semibold text-blue-900">Portfolio Details</Label>
    
    {/* Before Image */}
    <div className="space-y-2">
      <Label>Before Image (Optional)</Label>
      <ImageUploader
        currentImageUrl={metadata.before_image || ""}
        onImageUploaded={(url) => setMetadata({ ...metadata, before_image: url })}
      />
    </div>
    
    {/* After Image (already handled by main image field) */}
    <p className="text-sm text-blue-700">
      The main image field above will be used as the "After" image.
    </p>
    
    {/* Date */}
    <div className="space-y-2">
      <Label>Project Date</Label>
      <Input
        type="date"
        value={metadata.date || ""}
        onChange={(e) => setMetadata({ ...metadata, date: e.target.value })}
      />
    </div>
    
    {/* Industry */}
    <div className="space-y-2">
      <Label>Industry/Category</Label>
      <Input
        value={metadata.industry || ""}
        onChange={(e) => setMetadata({ ...metadata, industry: e.target.value })}
        placeholder="Food & Beverage"
      />
    </div>
    
    {/* Results */}
    <div className="space-y-2">
      <div className="flex justify-between items-center">
        <Label>Results/Metrics</Label>
        <Button
          type="button"
          size="sm"
          onClick={() => setMetadata({ 
            ...metadata, 
            results: [...(metadata.results || []), ""] 
          })}
        >
          + Add Result
        </Button>
      </div>
      
      {(metadata.results || []).map((result: string, index: number) => (
        <div key={index} className="flex gap-2">
          <Input
            value={result}
            onChange={(e) => {
              const updated = [...(metadata.results || [])];
              updated[index] = e.target.value;
              setMetadata({ ...metadata, results: updated });
            }}
            placeholder="50% increase in online orders"
          />
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => {
              const updated = (metadata.results || []).filter((_: any, i: number) => i !== index);
              setMetadata({ ...metadata, results: updated });
            }}
          >
            Remove
          </Button>
        </div>
      ))}
    </div>
  </div>
)}
```

**6. Update Schema and Types**

Already covered in steps 1-2 above.

**7. Test**

1. Deploy migration: `supabase db push`
2. Restart dev server: `npm run dev`
3. Add portfolio item in admin
4. View on homepage
5. Test before/after toggle
6. Test navigation between projects

---

## Security & Authentication

### Authentication Flow

**Supabase Auth** is used for admin authentication:

1. **Login Page**: `app/login/page.tsx`
   - Email/password form
   - Calls `supabase.auth.signInWithPassword()`
   - Redirects to `/admin` on success

2. **Admin Layout Middleware**: `app/admin/layout.tsx`
   - Checks for active session
   - Redirects to `/login` if not authenticated
   - Passes user data to admin pages

3. **Row-Level Security (RLS)**:
   - Database policies enforce authentication
   - Public can only read `is_active = true` content
   - Authenticated users have full CRUD access
   - Policy example:
     ```sql
     CREATE POLICY "Authenticated users have full access"
       ON landing_content
       FOR ALL
       USING (auth.role() = 'authenticated')
       WITH CHECK (auth.role() = 'authenticated');
     ```

### Protecting API Routes

**Example: `/api/revalidate/route.ts`**

```typescript
export async function POST(request: NextRequest) {
  // Optional secret token
  const secret = request.headers.get("x-revalidate-secret");
  const expectedSecret = process.env.REVALIDATE_SECRET;

  if (expectedSecret && secret !== expectedSecret) {
    return NextResponse.json({ message: "Invalid secret" }, { status: 401 });
  }

  // ... revalidate logic
}
```

### Environment Variables

**Required variables** (`.env.local`):

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Optional
REVALIDATE_SECRET=your-secret-for-revalidation
```

---

## Deployment & Revalidation

### Cache Revalidation Strategy

**Problem**: Next.js caches server-rendered pages. When admin updates content, cache must be cleared.

**Solution**: On-demand revalidation via API route.

#### Revalidation Flow

```
Admin saves content
     ↓
Supabase update succeeds
     ↓
POST /api/revalidate { path: "/" }
     ↓
revalidatePath("/", "page")
     ↓
Next.js clears cache for home page
     ↓
Next user request fetches fresh data
```

#### API Route Implementation

**File: `app/api/revalidate/route.ts`**

```typescript
import { revalidatePath } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  try {
    // Optional secret validation
    const secret = request.headers.get("x-revalidate-secret");
    if (process.env.REVALIDATE_SECRET && secret !== process.env.REVALIDATE_SECRET) {
      return NextResponse.json({ message: "Invalid secret" }, { status: 401 });
    }

    // Get path to revalidate
    const body = await request.json();
    const path = body.path || "/";

    // Clear cache
    revalidatePath(path, "page");

    return NextResponse.json({
      revalidated: true,
      path,
      now: Date.now(),
    });
  } catch (err: any) {
    return NextResponse.json(
      { message: "Error revalidating", error: err.message },
      { status: 500 }
    );
  }
}
```

#### Client-Side Trigger

**In any admin component after data mutation**:

```typescript
// After insert/update/delete
await fetch("/api/revalidate", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ path: "/" }),
});
```

#### Time-Based Revalidation

**File: `app/(public)/page.tsx`**

```typescript
export const revalidate = 10; // Revalidate every 10 seconds

export default async function Home() {
  // ... fetch and render
}
```

This ensures that even without manual revalidation, the page refreshes every 10 seconds.

### Deployment Checklist

1. **Set environment variables** in hosting platform (Vercel, Netlify, etc.)
2. **Deploy database migrations** to production Supabase project
3. **Create admin user** in Supabase Auth
4. **Configure storage bucket** permissions
5. **Test authentication** flow in production
6. **Verify RLS policies** are active
7. **Test content updates** and revalidation

---

## Summary

This architecture provides:

✅ **Flexible Content Management**: Admin can manage any type of content without code changes  
✅ **Type-Safe Database Access**: TypeScript types ensure data integrity  
✅ **Secure by Default**: RLS policies and authentication protect admin functions  
✅ **Real-Time Updates**: Revalidation ensures changes appear immediately  
✅ **Scalable Structure**: Easy to add new sections and content types  
✅ **Audit Trail**: Complete history of all content changes  
✅ **Image Management**: Integrated upload and storage system  

### Key Files Reference

| Purpose | File Path |
|---------|-----------|
| Admin Dashboard | `app/admin/page.tsx` |
| Content Editor | `components/admin/ContentEditor.tsx` |
| Settings Form | `components/admin/SettingsForm.tsx` |
| Image Uploader | `components/admin/ImageUploader.tsx` |
| Content List | `components/admin/ContentList.tsx` |
| Public Page | `app/(public)/page.tsx` |
| Content Fetching | `lib/content-public.ts` |
| Settings Fetching | `lib/settings-public.ts` |
| Database Types | `types/database.types.ts` |
| Content Types | `types/content.types.ts` |
| Settings Types | `types/settings.types.ts` |
| Schema Validation | `schemas/content.schema.ts` |
| Revalidation API | `app/api/revalidate/route.ts` |
| Database Migration | `supabase/migrations/001_create_landing_content.sql` |

### Next Steps for Extension

When adding new features, follow this pattern:

1. **Identify user needs** (interview/questionnaire)
2. **Design data structure** (what fields, what metadata)
3. **Update database** (migration to add section)
4. **Update types** (TypeScript interfaces)
5. **Create React component** (display logic)
6. **Add to public page** (include in render)
7. **Update admin editor** (add section config and metadata fields)
8. **Test thoroughly** (create, edit, delete, view)

This architecture is designed to be extended incrementally without disrupting existing functionality.

