/*
  # Add additional profile fields

  1. Changes
    - Add new columns to profiles table:
      - full_name
      - avatar_url
      - website
      - location
      - bio
*/

-- Add new columns to profiles table
ALTER TABLE profiles
ADD COLUMN full_name text,
ADD COLUMN avatar_url text,
ADD COLUMN website text,
ADD COLUMN location text,
ADD COLUMN bio text;

-- Update handle_new_user function to include full_name
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
  INSERT INTO public.profiles (
    id,
    username,
    referral_code,
    full_name
  )
  VALUES (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'referral_code',
    new.raw_user_meta_data->>'full_name'
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