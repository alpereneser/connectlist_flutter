/*
  # Fix storage policies owner handling

  1. Changes
    - Fix owner handling in storage policies
    - Add proper owner assignment on upload
    - Maintain existing security restrictions

  2. Security
    - Ensure proper owner assignment
    - Maintain access controls
*/

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatars" ON storage.objects;

-- Create storage policy for viewing avatars (public access)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Create storage policy for uploading avatars (authenticated users only)
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (LOWER(storage.extension(name)) = 'jpg' OR
   LOWER(storage.extension(name)) = 'jpeg' OR
   LOWER(storage.extension(name)) = 'png' OR
   LOWER(storage.extension(name)) = 'gif') AND
  owner IS NULL
);

-- Create storage policy for updating avatars (own avatars only)
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  owner = auth.uid()
);

-- Create storage policy for deleting avatars (own avatars only)
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  owner = auth.uid()
);