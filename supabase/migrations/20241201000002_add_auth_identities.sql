-- Note: In production Supabase, the auth.identities table already exists
-- For production, just run the INSERT statement below directly

-- FOR PRODUCTION: Run this in Supabase SQL Editor
-- Add identity records for existing users (Production version - uses UUID)
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
    u.id,  -- Production uses UUID type, no casting needed
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
);

