/*
  # Add followers system

  1. New Tables
    - `follows`
      - `follower_id` (uuid, references profiles.id)
      - `following_id` (uuid, references profiles.id)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `follows` table
    - Add policies for followers management
*/

-- Create follows table
CREATE TABLE follows (
  follower_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  following_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

-- Enable RLS
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can see who they follow and who follows them"
  ON follows
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = follower_id OR 
    auth.uid() = following_id
  );

CREATE POLICY "Users can follow others"
  ON follows
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
  ON follows
  FOR DELETE
  TO authenticated
  USING (auth.uid() = follower_id);

-- Create indexes for better performance
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- Add functions to get follower and following counts
CREATE OR REPLACE FUNCTION get_follower_count(profile_id uuid)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COUNT(*)
  FROM follows
  WHERE following_id = profile_id;
$$;

CREATE OR REPLACE FUNCTION get_following_count(profile_id uuid)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COUNT(*)
  FROM follows
  WHERE follower_id = profile_id;
$$;

-- Function to check if a user follows another user
CREATE OR REPLACE FUNCTION check_if_follows(follower uuid, following uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM follows
    WHERE follower_id = follower
    AND following_id = following
  );
$$;