-- First, let's see what we have in profiles and auth.users
WITH user_data AS (
  SELECT 
    u.id,
    u.email,
    split_part(u.email, '@', 1) as email_username,
    p.username as profile_username
  FROM auth.users u
  LEFT JOIN profiles p ON u.id = p.id
)
UPDATE profiles
SET username = ud.email_username
FROM user_data ud
WHERE profiles.id = ud.id
AND (profiles.username IS NULL OR profiles.username != ud.email_username);

-- Update the handle_new_user trigger to ensure username is always set correctly
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    username, 
    full_name, 
    avatar_url, 
    created_at, 
    updated_at,
    referral_code,
    role
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)), -- First try to get username from metadata, fallback to email
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)), -- Get full_name from metadata if exists
    NEW.raw_user_meta_data->>'avatar_url', -- Get avatar_url from metadata if exists
    NOW(),
    NOW(),
    LOWER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8)), -- Generate a random referral code
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
