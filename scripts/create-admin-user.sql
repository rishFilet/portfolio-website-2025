-- Create Admin User for Portfolio Website
-- Run this in your Supabase SQL Editor or psql

-- Create the user in auth.users table
-- Replace 'your-email@example.com' with your desired email
-- Replace 'your-secure-password' with your desired password

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  raw_app_meta_data,
  raw_user_meta_data
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@example.com',  -- ⬅️ CHANGE THIS to your email
  crypt('MySecurePassword123', gen_salt('bf')),  -- ⬅️ CHANGE THIS to your password
  NOW(),
  NOW(),
  NOW(),
  '',
  '{"provider":"email","providers":["email"]}',
  '{}'
);

-- Verify the user was created
SELECT id, email, created_at, email_confirmed_at 
FROM auth.users 
WHERE email = 'admin@example.com';  -- ⬅️ Use your email here

-- IMPORTANT: After creating the user, you can log in at:
-- http://localhost:3002/login

