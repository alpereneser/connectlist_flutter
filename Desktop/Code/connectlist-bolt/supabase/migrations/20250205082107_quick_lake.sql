/*
  # Add search function for profiles

  1. New Functions
    - `search_profiles`: Function to search profiles by full name or username
  2. Changes
    - Adds a function that searches both full_name and username fields
    - Returns results ordered by relevance (full name matches first)
*/

-- Create function to search profiles
CREATE OR REPLACE FUNCTION search_profiles(search_query text)
RETURNS SETOF profiles
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT DISTINCT ON (p.id) p.*
  FROM profiles p
  WHERE 
    -- Search in full_name if it exists
    (p.full_name IS NOT NULL AND p.full_name ILIKE '%' || search_query || '%')
    OR 
    -- Search in username if no full_name or as fallback
    (p.username ILIKE '%' || search_query || '%')
  ORDER BY 
    p.id,
    -- Prioritize full_name matches
    CASE WHEN p.full_name ILIKE '%' || search_query || '%' THEN 0 ELSE 1 END,
    -- Then username matches
    CASE WHEN p.username ILIKE '%' || search_query || '%' THEN 0 ELSE 1 END,
    -- Finally by username alphabetically
    p.username ASC;
$$;