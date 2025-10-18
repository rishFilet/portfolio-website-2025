-- Note: In production Supabase, the auth.identities table already exists
-- This migration handles both local dev and production environments

-- Create identities table only if it doesn't exist (local development)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' AND tablename = 'identities'
    ) THEN
        CREATE TABLE auth.identities (
            id text NOT NULL,
            user_id uuid NOT NULL,
            identity_data jsonb NOT NULL,
            provider text NOT NULL,
            last_sign_in_at timestamp with time zone,
            created_at timestamp with time zone,
            updated_at timestamp with time zone,
            email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
            CONSTRAINT identities_pkey PRIMARY KEY (provider, id),
            CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) 
                REFERENCES auth.users(id) ON DELETE CASCADE
        );

        CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);
        CREATE INDEX identities_email_idx ON auth.identities USING btree (email);
    END IF;
END $$;

-- Add identity for existing users
-- Dynamically detect if id column is UUID or text
DO $$
DECLARE
    id_is_uuid boolean;
BEGIN
    -- Check if the id column in identities is UUID type
    SELECT data_type = 'uuid' INTO id_is_uuid
    FROM information_schema.columns
    WHERE table_schema = 'auth' 
    AND table_name = 'identities' 
    AND column_name = 'id';

    -- Insert with appropriate type
    IF id_is_uuid THEN
        -- Production Supabase uses UUID
        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        )
        SELECT 
            u.id,
            u.id,
            jsonb_build_object(
                'sub', u.id::text,
                'email', u.email,
                'email_verified', true,
                'provider', 'email'
            ),
            'email',
            NOW(),
            u.created_at,
            u.updated_at
        FROM auth.users u
        WHERE NOT EXISTS (
            SELECT 1 FROM auth.identities i 
            WHERE i.user_id = u.id AND i.provider = 'email'
        )
        ON CONFLICT (provider, id) DO NOTHING;
    ELSE
        -- Local dev uses text
        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        )
        SELECT 
            u.id::text,
            u.id,
            jsonb_build_object(
                'sub', u.id::text,
                'email', u.email,
                'email_verified', true,
                'provider', 'email'
            ),
            'email',
            NOW(),
            u.created_at,
            u.updated_at
        FROM auth.users u
        WHERE NOT EXISTS (
            SELECT 1 FROM auth.identities i 
            WHERE i.user_id = u.id AND i.provider = 'email'
        )
        ON CONFLICT (provider, id) DO NOTHING;
    END IF;
END $$;

