#!/usr/bin/env python3
"""
Import Strapi backup data into Supabase local database.
This script transforms Strapi schema to match Supabase schema.
"""

import re
import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values
import sys
from datetime import datetime
import hashlib

# Database connection details
DB_CONFIG = {
    "host": "127.0.0.1",
    "port": "54332",
    "database": "postgres",
    "user": "postgres",
    "password": "postgres",
}


def parse_copy_data(backup_file_path, table_name):
    """Parse COPY data from the backup file for a specific table"""
    print(f"Parsing {table_name} from backup...")
    data = []
    in_copy_block = False
    copy_pattern = rf"^COPY public\.{re.escape(table_name)}\s+\((.*?)\)\s+FROM stdin;$"

    with open(backup_file_path, "r", encoding="utf-8") as f:
        columns = None
        for line in f:
            # Check for COPY statement
            match = re.match(copy_pattern, line)
            if match:
                in_copy_block = True
                columns = [col.strip(' "') for col in match.group(1).split(",")]
                continue

            # Check for end of COPY block
            if in_copy_block and line.strip() == "\\.":
                in_copy_block = False
                break

            # Parse data lines
            if in_copy_block and columns:
                # Split by tabs, handling NULL values
                values = line.rstrip("\n").split("\t")
                row_dict = {}
                for i, col in enumerate(columns):
                    if i < len(values):
                        val = values[i]
                        # Handle NULL values
                        if val == "\\N":
                            row_dict[col] = None
                        else:
                            row_dict[col] = val
                data.append(row_dict)

    print(f"Found {len(data)} rows in {table_name}")
    return data, columns if data else None


def create_slug(title):
    """Create a URL-friendly slug from a title"""
    slug = title.lower()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[-\s]+", "-", slug)
    return slug[:255]


def import_blog_posts(cursor, backup_file):
    """Import blog posts from Strapi to Supabase"""
    data, columns = parse_copy_data(backup_file, "blog_posts")
    if not data:
        print("No blog posts found in backup")
        return

    print("Importing blog posts...")
    for row in data:
        # Map Strapi fields to Supabase fields
        title = row.get("title", "Untitled")
        slug = row.get("slug") or create_slug(title)
        post_content = row.get("post_content", "")
        post_summary = row.get("post_summary")
        likes = (
            int(row.get("likes", 0))
            if row.get("likes") and row.get("likes") != "\\N"
            else 0
        )

        # Handle published status
        is_published = (
            row.get("published_at") is not None and row.get("published_at") != "\\N"
        )

        try:
            cursor.execute(
                """
                INSERT INTO blog_posts (title, slug, post_content, post_summary, likes, is_published, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, COALESCE(%s::timestamp, NOW()), COALESCE(%s::timestamp, NOW()))
                ON CONFLICT (slug) DO UPDATE SET
                    title = EXCLUDED.title,
                    post_content = EXCLUDED.post_content,
                    post_summary = EXCLUDED.post_summary,
                    likes = EXCLUDED.likes,
                    is_published = EXCLUDED.is_published,
                    updated_at = EXCLUDED.updated_at
                RETURNING id
            """,
                (
                    title,
                    slug,
                    post_content,
                    post_summary,
                    likes,
                    is_published,
                    row.get("created_at"),
                    row.get("updated_at"),
                ),
            )

            blog_id = cursor.fetchone()[0]
            print(f"  ✓ Imported blog post: {title} (ID: {blog_id})")
        except Exception as e:
            print(f"  ✗ Error importing blog post '{title}': {e}")
            continue


def import_project_posts(cursor, backup_file):
    """Import project posts from Strapi to Supabase"""
    data, columns = parse_copy_data(backup_file, "project_posts")
    if not data:
        print("No project posts found in backup")
        return

    print("Importing project posts...")
    for row in data:
        title = row.get("title", "Untitled Project")
        slug = create_slug(title)
        project_summary = row.get("project_summary")
        project_url = row.get("project_url")
        is_published = (
            row.get("published_at") is not None and row.get("published_at") != "\\N"
        )

        try:
            cursor.execute(
                """
                INSERT INTO project_posts (title, slug, project_summary, project_url, is_published, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, COALESCE(%s::timestamp, NOW()), COALESCE(%s::timestamp, NOW()))
                ON CONFLICT (slug) DO UPDATE SET
                    title = EXCLUDED.title,
                    project_summary = EXCLUDED.project_summary,
                    project_url = EXCLUDED.project_url,
                    is_published = EXCLUDED.is_published,
                    updated_at = EXCLUDED.updated_at
                RETURNING id
            """,
                (
                    title,
                    slug,
                    project_summary,
                    project_url,
                    is_published,
                    row.get("created_at"),
                    row.get("updated_at"),
                ),
            )

            project_id = cursor.fetchone()[0]
            print(f"  ✓ Imported project: {title} (ID: {project_id})")
        except Exception as e:
            print(f"  ✗ Error importing project '{title}': {e}")
            continue


def import_landing_page(cursor, backup_file):
    """Import landing page content from Strapi to Supabase"""
    data, columns = parse_copy_data(backup_file, "landing_pages")
    if not data or len(data) == 0:
        print("No landing page data found in backup")
        return

    print("Importing landing page content...")
    # Take the first (or most recent) landing page entry
    row = (
        data[0] if len(data) == 1 else max(data, key=lambda x: x.get("updated_at", ""))
    )

    header = row.get("header", "Welcome")
    description = row.get("description", "")
    sub_headers = row.get("comma_separated_sub_headers_string", "")

    try:
        cursor.execute(
            """
            INSERT INTO landing_page_content (header, description, sub_headers, created_at, updated_at)
            VALUES (%s, %s, %s, COALESCE(%s::timestamp, NOW()), COALESCE(%s::timestamp, NOW()))
            ON CONFLICT (id) DO UPDATE SET
                header = EXCLUDED.header,
                description = EXCLUDED.description,
                sub_headers = EXCLUDED.sub_headers,
                updated_at = EXCLUDED.updated_at
        """,
            (
                header,
                description,
                sub_headers,
                row.get("created_at"),
                row.get("updated_at"),
            ),
        )

        print(f"  ✓ Imported landing page: {header}")
    except Exception as e:
        print(f"  ✗ Error importing landing page: {e}")


def import_social_links(cursor, backup_file):
    """Import social links from Strapi to Supabase"""
    data, columns = parse_copy_data(backup_file, "social_links")
    if not data:
        print("No social links found in backup")
        return

    print("Importing social links...")
    for row in data:
        display_name = row.get("display_name", "Social Link")
        link_url = row.get("link")
        icon_code = row.get("icon_shortcode", "fas fa-link")

        if not link_url:
            print(f"  ⚠ Skipping social link with no URL: {display_name}")
            continue

        try:
            # Check if link already exists
            cursor.execute("SELECT id FROM social_links WHERE link = %s", (link_url,))
            existing = cursor.fetchone()

            if existing:
                # Update existing
                cursor.execute(
                    """
                    UPDATE social_links 
                    SET display_name = %s, icon_shortcode = %s, updated_at = COALESCE(%s::timestamp, NOW())
                    WHERE link = %s
                """,
                    (display_name, icon_code, row.get("updated_at"), link_url),
                )
                print(f"  ✓ Updated social link: {display_name}")
            else:
                # Insert new
                cursor.execute(
                    """
                    INSERT INTO social_links (display_name, link, icon_shortcode, created_at, updated_at)
                    VALUES (%s, %s, %s, COALESCE(%s::timestamp, NOW()), COALESCE(%s::timestamp, NOW()))
                """,
                    (
                        display_name,
                        link_url,
                        icon_code,
                        row.get("created_at"),
                        row.get("updated_at"),
                    ),
                )
                print(f"  ✓ Imported social link: {display_name}")
        except Exception as e:
            print(f"  ✗ Error importing social link '{display_name}': {e}")
            continue


def import_tags(cursor, backup_file):
    """Import tags from Strapi to Supabase"""
    data, columns = parse_copy_data(backup_file, "tags")
    if not data:
        print("No tags found in backup")
        return

    print("Importing tags...")
    for row in data:
        tag_name = row.get("name") or row.get("tag", "Uncategorized")

        try:
            cursor.execute(
                """
                INSERT INTO tags (name, created_at, updated_at)
                VALUES (%s, COALESCE(%s::timestamp, NOW()), COALESCE(%s::timestamp, NOW()))
                ON CONFLICT (name) DO NOTHING
            """,
                (tag_name, row.get("created_at"), row.get("updated_at")),
            )

            print(f"  ✓ Imported tag: {tag_name}")
        except Exception as e:
            print(f"  ✗ Error importing tag '{tag_name}': {e}")
            continue


def import_technologies(cursor, backup_file):
    """Import technologies from Strapi to Supabase"""
    data, columns = parse_copy_data(backup_file, "technologies")
    if not data:
        print("No technologies found in backup")
        return

    print("Importing technologies...")
    for row in data:
        tech_name = row.get("name") or row.get("technology", "Unknown")

        try:
            cursor.execute(
                """
                INSERT INTO technologies (name, created_at, updated_at)
                VALUES (%s, COALESCE(%s::timestamp, NOW()), COALESCE(%s::timestamp, NOW()))
                ON CONFLICT (name) DO NOTHING
            """,
                (tech_name, row.get("created_at"), row.get("updated_at")),
            )

            print(f"  ✓ Imported technology: {tech_name}")
        except Exception as e:
            print(f"  ✗ Error importing technology '{tech_name}': {e}")
            continue


def main():
    backup_file = "/Users/rishfilet/Downloads/db_cluster-11-04-2025@00-21-56.backup"

    print("=" * 60)
    print("Strapi to Supabase Import Script")
    print("=" * 60)
    print(f"Backup file: {backup_file}")
    print(
        f"Target database: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    )
    print()

    # Connect to database
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✓ Connected to Supabase local database\n")
    except Exception as e:
        print(f"✗ Failed to connect to database: {e}")
        sys.exit(1)

    try:
        # Import data in order (dependencies first)
        import_tags(cursor, backup_file)
        import_technologies(cursor, backup_file)
        import_landing_page(cursor, backup_file)
        import_social_links(cursor, backup_file)
        import_blog_posts(cursor, backup_file)
        import_project_posts(cursor, backup_file)

        # Commit transaction
        conn.commit()
        print("\n" + "=" * 60)
        print("✓ Import completed successfully!")
        print("=" * 60)

    except Exception as e:
        conn.rollback()
        print(f"\n✗ Import failed: {e}")
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()
