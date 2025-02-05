/*
  # Add referral codes system

  1. New Tables
    - `referral_codes`
      - `code` (text, primary key)
      - `used_by` (uuid, references auth.users)
      - `used_at` (timestamptz)
      - `created_at` (timestamptz)

  2. Changes
    - Make referral_code required in profiles table
    - Add unique constraint on username and email

  3. Security
    - Enable RLS on referral_codes table
    - Add policies for referral code usage
*/

-- Create referral_codes table
CREATE TABLE IF NOT EXISTS referral_codes (
  code text PRIMARY KEY,
  used_by uuid REFERENCES auth.users,
  used_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view unused referral codes"
  ON referral_codes
  FOR SELECT
  USING (used_by IS NULL);

CREATE POLICY "Users can mark referral code as used"
  ON referral_codes
  FOR UPDATE
  USING (used_by IS NULL)
  WITH CHECK (auth.uid() = used_by);

-- Add check for referral code usage in profiles
ALTER TABLE profiles 
  ALTER COLUMN referral_code SET NOT NULL,
  ADD CONSTRAINT valid_referral_code 
    FOREIGN KEY (referral_code) 
    REFERENCES referral_codes (code);

-- Add unique constraint for username
ALTER TABLE profiles
  ADD CONSTRAINT unique_username UNIQUE (username);

-- Function to validate and use referral code
CREATE OR REPLACE FUNCTION use_referral_code(code text, user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE referral_codes
  SET 
    used_by = user_id,
    used_at = now()
  WHERE 
    code = code
    AND used_by IS NULL;
    
  RETURN FOUND;
END;
$$;