/*
  # User Roles System

  1. New Tables
    - `roles`
      - `id` (text, primary key) - Role identifier
      - `description` (text) - Role description
      - `created_at` (timestamp)

  2. Changes to Existing Tables
    - Add `role` column to `profiles` table
    - Set default role to 'user'
    - Create foreign key constraint

  3. Initial Data
    - Insert predefined roles
    - Set specific user as admin
*/

-- Create roles table
CREATE TABLE IF NOT EXISTS roles (
  id text PRIMARY KEY,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- Create policy for reading roles
CREATE POLICY "Anyone can read roles"
  ON roles
  FOR SELECT
  TO authenticated
  USING (true);

-- Insert predefined roles
INSERT INTO roles (id, description) VALUES
  ('admin', 'Full system access and control'),
  ('editor', 'Can edit and manage content'),
  ('writer', 'Can create and edit own content'),
  ('user', 'Basic user access')
ON CONFLICT (id) DO NOTHING;

-- Add role column to profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'user'
REFERENCES roles(id);

-- Update handle_new_user function to include role
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
DECLARE
  referral_code_exists boolean;
  user_email text;
BEGIN
  -- Get user's email
  user_email := new.email;

  -- Check if referral code exists and is unused
  SELECT EXISTS (
    SELECT 1 
    FROM public.referral_codes 
    WHERE code = (new.raw_user_meta_data->>'referral_code')
    AND used_by IS NULL
  ) INTO referral_code_exists;

  IF NOT referral_code_exists THEN
    RAISE EXCEPTION 'Invalid or already used referral code';
  END IF;

  -- Insert the profile with role
  INSERT INTO public.profiles (
    id,
    username,
    referral_code,
    full_name,
    role
  )
  VALUES (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'referral_code',
    new.raw_user_meta_data->>'full_name',
    CASE
      WHEN user_email = 'alperen@connectlist.me' THEN 'admin'
      ELSE 'user'
    END
  );

  -- Mark referral code as used
  UPDATE public.referral_codes
  SET 
    used_by = new.id,
    used_at = now()
  WHERE 
    code = (new.raw_user_meta_data->>'referral_code')
    AND used_by IS NULL;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;