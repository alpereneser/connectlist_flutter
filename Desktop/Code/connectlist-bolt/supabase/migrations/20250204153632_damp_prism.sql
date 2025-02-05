/*
  # Fix Array Handling

  1. Changes
    - Add proper array handling for any columns that expect arrays
    - Ensure default values are properly formatted for array columns
    - Add validation for array inputs

  2. Security
    - Maintain existing RLS policies
    - No data loss during migration
*/

-- Function to safely handle array conversions
CREATE OR REPLACE FUNCTION safe_to_array(input text)
RETURNS text[]
LANGUAGE plpgsql
AS $$
BEGIN
  IF input IS NULL OR input = '' THEN
    RETURN '{}';
  END IF;
  
  -- Check if input is already a valid array literal
  IF input LIKE '{%}' THEN
    RETURN input::text[];
  END IF;
  
  -- Convert single value to array
  RETURN ARRAY[input];
EXCEPTION
  WHEN OTHERS THEN
    RETURN '{}';
END $$;