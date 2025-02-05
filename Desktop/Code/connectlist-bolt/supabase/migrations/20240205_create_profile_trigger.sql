-- Create a function to handle new user creation
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
    referral_code
  )
  VALUES (
    NEW.id,
    split_part(NEW.email, '@', 1), -- Use email username as initial username
    NEW.raw_user_meta_data->>'full_name', -- Get full_name from metadata if exists
    NEW.raw_user_meta_data->>'avatar_url', -- Get avatar_url from metadata if exists
    NOW(),
    NOW(),
    LOWER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8)) -- Generate a random referral code
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger to automatically create profile for new users
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill existing users
INSERT INTO public.profiles (id, username, created_at, updated_at, referral_code)
SELECT 
  id,
  split_part(email, '@', 1),
  COALESCE(created_at, NOW()),
  COALESCE(last_sign_in_at, NOW()),
  LOWER(SUBSTRING(MD5(id::text || NOW()::text) FROM 1 FOR 8)) -- Generate a random referral code
FROM auth.users
ON CONFLICT (id) DO NOTHING;
