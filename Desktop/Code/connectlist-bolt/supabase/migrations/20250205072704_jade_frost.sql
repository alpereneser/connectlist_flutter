/*
  # Fix storage setup for avatars

  1. Storage Configuration
    - Enable storage extension
    - Create avatars bucket
    - Set up RLS policies for avatars bucket
    - Configure file size limits and MIME types

  2. Security
    - Enable public read access
    - Restrict write access to authenticated users
    - Add policies for file management
*/

-- Create the storage schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS storage;

-- Create the storage extension in the storage schema
CREATE EXTENSION IF NOT EXISTS "storage" WITH SCHEMA "storage";

-- Create avatars bucket if it doesn't exist
DO $$
BEGIN
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', true)
  ON CONFLICT (id) DO NOTHING;

  -- Create storage policy for viewing avatars (public access)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view avatars'
  ) THEN
    CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');
  END IF;

  -- Create storage policy for uploading avatars (authenticated users only)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can upload avatars'
  ) THEN
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
  END IF;

  -- Create storage policy for updating avatars (own avatars only)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own avatars'
  ) THEN
    CREATE POLICY "Users can update own avatars"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'avatars' AND auth.uid()::text = owner)
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = owner);
  END IF;

  -- Create storage policy for deleting avatars (own avatars only)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete own avatars'
  ) THEN
    CREATE POLICY "Users can delete own avatars"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'avatars' AND auth.uid()::text = owner);
  END IF;
END $$;