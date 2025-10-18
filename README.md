# Portfolio Website with Admin Interface

This is a portfolio website with a custom admin interface built using Next.js, Supabase, and Tailwind CSS. The admin interface allows you to manage blog posts, projects, page content, and social links.

## Features

### Admin Interface

- **Dashboard**: Overview of content statistics and quick actions
- **Blog Management**: Create, edit, and delete blog posts with tags
- **Project Management**: Create, edit, and delete projects with technologies
- **Page Content**: Edit landing page and about page content
- **Social Links**: Manage social media links and icons
- **Authentication**: Secure login system using Supabase Auth

### Frontend Features

- Modern, responsive design with Tailwind CSS
- Blog posts with markdown support
- Project showcase with technology tags
- Dynamic content management
- SEO optimized

## Tech Stack

- **Frontend**: Next.js 15, React 19, TypeScript
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Styling**: Tailwind CSS
- **Deployment**: Vercel (recommended)

## Setup Instructions

### 1. Prerequisites

- Node.js 18+ and pnpm
- Supabase account
- Git

### 2. Clone and Install Dependencies

```bash
git clone <your-repo-url>
cd portfolio-website-2025
cd frontend
pnpm install
```

### 3. Set up Supabase

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from the API settings
3. Run the database migrations:

```bash
cd backend-supabase
supabase init
supabase start
supabase db reset
```

### 4. Environment Variables

Create a `.env.local` file in the `frontend` directory:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 5. Install Supabase CLI (Optional)

For local development with Supabase:

```bash
npm install -g supabase
```

### 6. Start Development Server

```bash
cd frontend
pnpm dev
```

The admin interface will be available at `http://localhost:3000/admin`

## Database Schema

The application uses the following main tables:

- `blog_posts`: Blog post content and metadata
- `blog_post_images`: Images associated with blog posts
- `blog_post_tags`: Many-to-many relationship between posts and tags
- `project_posts`: Project information and metadata
- `project_post_images`: Images associated with projects
- `project_post_technologies`: Many-to-many relationship between projects and technologies
- `landing_page_content`: Landing page content and hero image
- `about_page_content`: About page content and profile image
- `social_links`: Social media links and icons
- `tags`: Blog post tags
- `technologies`: Project technologies

## Admin Interface Usage

### Authentication

1. Navigate to `/admin/login`
2. Sign in with your Supabase user credentials
3. You'll be redirected to the admin dashboard

### Managing Content

#### Blog Posts

- **Create**: Navigate to `/admin/blogs/new`
- **Edit**: Click "Edit" on any blog post in the list
- **Delete**: Click "Delete" on any blog post (with confirmation)
- **Publish**: Toggle the "Publish this post" checkbox

#### Projects

- **Create**: Navigate to `/admin/projects/new`
- **Edit**: Click "Edit" on any project in the list
- **Delete**: Click "Delete" on any project (with confirmation)
- **Publish**: Toggle the "Publish this project" checkbox

#### Page Content

- **Landing Page**: Edit header, description, sub-headers, and hero image
- **About Page**: Edit title, content, and profile image

#### Social Links

- **Add**: Click "Add Link" to create new social media links
- **Edit**: Modify display name, icon shortcode, and URL
- **Remove**: Click "Remove" to delete social links

## Customization

### Styling

The admin interface uses Tailwind CSS. You can customize the styling by modifying the classes in the components.

### Adding New Features

1. Create new database tables in Supabase
2. Add corresponding types in `frontend/src/lib/supabase/client.ts`
3. Create new admin pages and components
4. Update the navigation in `AdminNavbar.tsx`

### Image Upload

Currently, the interface supports image URLs. For file uploads, you can integrate Supabase Storage:

```typescript
// Example file upload
const { data, error } = await supabase.storage
  .from("images")
  .upload("path/to/file.jpg", file);
```

## Deployment

### Vercel (Recommended)

1. Connect your GitHub repository to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

### Environment Variables for Production

Make sure to set these in your deployment platform:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Security Considerations

1. **Row Level Security (RLS)**: Enable RLS on your Supabase tables
2. **Authentication**: Use Supabase Auth for secure admin access
3. **Environment Variables**: Never commit sensitive keys to version control
4. **CORS**: Configure CORS settings in Supabase for production domains

## Troubleshooting

### Common Issues

1. **Supabase Connection Error**: Check your environment variables
2. **Authentication Issues**: Ensure your Supabase user has the correct permissions
3. **Database Errors**: Run `supabase db reset` to reset the database schema

### Getting Help

1. Check the Supabase documentation
2. Review the Next.js documentation
3. Check the Tailwind CSS documentation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.
