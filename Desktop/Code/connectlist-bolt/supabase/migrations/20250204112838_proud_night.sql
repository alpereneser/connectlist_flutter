-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  username text UNIQUE NOT NULL,
  referral_code text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
DECLARE
  referral_code_exists boolean;
BEGIN
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

  -- Insert the profile
  INSERT INTO public.profiles (id, username, referral_code)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'referral_code'
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

-- Create trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();