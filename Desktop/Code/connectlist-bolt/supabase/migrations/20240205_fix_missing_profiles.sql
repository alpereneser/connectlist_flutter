-- First, let's see which users are missing profiles
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
  COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  LOWER(SUBSTRING(MD5(u.id::text || NOW()::text) FROM 1 FOR 8)),
  NOW(),
  NOW(),
  'user'
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;
