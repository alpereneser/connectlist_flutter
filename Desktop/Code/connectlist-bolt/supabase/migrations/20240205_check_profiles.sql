-- Check all profiles
SELECT 
  p.id,
  p.username,
  p.full_name,
  u.email,
  u.raw_user_meta_data
FROM profiles p
JOIN auth.users u ON u.id = p.id;
