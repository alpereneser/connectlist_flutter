-- First, let's update existing profiles with missing full_name
UPDATE profiles p
SET 
  full_name = COALESCE(
    p.full_name,
    (SELECT split_part(email, '@', 1) FROM auth.users WHERE id = p.id)
  ),
  updated_at = NOW()
WHERE p.full_name IS NULL;

-- Update the handle_new_user trigger to ensure full_name is always set
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
    split_part(NEW.email, '@', 1),
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.raw_user_meta_data->>'avatar_url',
    NOW(),
    NOW(),
    LOWER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8)),
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
