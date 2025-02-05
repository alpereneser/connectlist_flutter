/*
  # Fix Content Types Relationship

  1. Changes
    - Remove array reference from people table
    - Create people_content_types junction table
    - Add proper foreign key constraints

  2. Security
    - Enable RLS on new table
    - Add policy for authenticated users
*/

-- Remove the problematic column from people table
ALTER TABLE people DROP COLUMN IF EXISTS content_types;

-- Create junction table for people and content types
CREATE TABLE people_content_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  content_type_id uuid NOT NULL REFERENCES content_types(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(person_id, content_type_id)
);

-- Enable RLS
ALTER TABLE people_content_types ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Enable read access for authenticated users" ON people_content_types
  FOR SELECT TO authenticated USING (true);

-- Create index for better performance
CREATE INDEX idx_people_content_types_person ON people_content_types(person_id);
CREATE INDEX idx_people_content_types_type ON people_content_types(content_type_id);