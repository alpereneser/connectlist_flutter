/*
  # Generate 1000 referral codes

  1. Changes
    - Insert 1000 unique referral codes into referral_codes table
    - Each code is 8 characters long, alphanumeric
*/

DO $$
DECLARE
  i integer;
  new_code text;
BEGIN
  FOR i IN 1..1000 LOOP
    -- Generate a unique 8-character code
    LOOP
      -- Generate random code: 2 letters + 4 numbers + 2 letters
      new_code := 
        chr(65 + floor(random() * 26)::integer) || -- First letter (A-Z)
        chr(65 + floor(random() * 26)::integer) || -- Second letter (A-Z)
        lpad(floor(random() * 10000)::text, 4, '0') || -- 4 digits (0000-9999)
        chr(65 + floor(random() * 26)::integer) || -- Third letter (A-Z)
        chr(65 + floor(random() * 26)::integer); -- Fourth letter (A-Z)
      
      -- Exit loop if code is unique
      EXIT WHEN NOT EXISTS (
        SELECT 1 FROM referral_codes WHERE code = new_code
      );
    END LOOP;
    
    -- Insert the unique code
    INSERT INTO referral_codes (code) VALUES (new_code);
  END LOOP;
END $$;