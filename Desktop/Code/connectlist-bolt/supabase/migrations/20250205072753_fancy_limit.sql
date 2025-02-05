/*
  # Fix storage setup for avatars

  1. Storage Configuration
    - Create avatars bucket
    - Set up RLS policies for avatars bucket
    - Configure file size limits and MIME types

  2. Security
    - Enable public read access
    - Restrict write access to authenticated users
    - Add policies for file management
*/

-- Create avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policy for viewing avatars (public access)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Create storage policy for uploading avatars (authenticated users only)
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.role() = 'authenticated' AND
  (LOWER(storage.extension(name)) = 'jpg' OR
   LOWER(storage.extension(name)) = 'jpeg' OR
   LOWER(storage.extension(name)) = 'png' OR
   LOWER(storage.extension(name)) = 'gif') AND
  storage.foldername(name) = '' AND
  (storage.filesize(name) / 1024 / 1024) < 2
);

-- Create storage policy for updating avatars (own avatars only)
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.uid()::text = owner)
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = owner);

-- Create storage policy for deleting avatars (own avatars only)
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars' AND auth.uid()::text = owner);