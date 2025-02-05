-- First, let's update existing profiles
WITH user_data AS (
  SELECT 
    u.id,
    u.email,
    u.raw_user_meta_data->>'name' as display_name,
    split_part(u.email, '@', 1) as email_username
  FROM auth.users u
)
UPDATE profiles p
SET 
  username = COALESCE(
    p.username,
    ud.email_username
  ),
  full_name = COALESCE(
    p.full_name,
    ud.display_name,
    ud.email_username
  ),
  referral_code = COALESCE(
    p.referral_code,
    LOWER(SUBSTRING(MD5(p.id::text || NOW()::text) FROM 1 FOR 8))
  ),
  updated_at = NOW()
FROM user_data ud
WHERE p.id = ud.id;

-- Insert missing profiles
INSERT INTO profiles (
  id,
  username,
  full_name,
  referral_code,
  created_at,
  updated_at,
  role
)
SELECT 
  u.id,
  split_part(u.email, '@', 1),
  COALESCE(u.raw_user_meta_data->>'name', split_part(u.email, '@', 1)),
  LOWER(SUBSTRING(MD5(u.id::text || NOW()::text) FROM 1 FOR 8)),
  NOW(),
  NOW(),
  'user'
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Update the handle_new_user trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    username,
    full_name,
    referral_code,
    created_at, 
    updated_at,
    role
  )
  VALUES (
    NEW.id,
    split_part(NEW.email, '@', 1),
    COALESCE(
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    LOWER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8)),
    NOW(),
    NOW(),
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
