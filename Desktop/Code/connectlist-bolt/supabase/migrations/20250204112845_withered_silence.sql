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

CREATE POLICY "Users can view their used referral code"
  ON referral_codes
  FOR SELECT
  USING (auth.uid() = used_by);

-- Add foreign key constraint for referral codes in profiles
ALTER TABLE profiles 
  ADD CONSTRAINT profiles_referral_code_fkey 
  FOREIGN KEY (referral_code) 
  REFERENCES referral_codes (code);

-- Create index for faster lookups
CREATE INDEX idx_referral_codes_used_by ON referral_codes(used_by);
CREATE INDEX idx_profiles_username ON profiles(username);