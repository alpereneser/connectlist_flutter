/*
  # Fix array initialization in tables

  1. Changes
    - Add default empty array values for array columns
    - Update existing null arrays to empty arrays
    - Add check constraints to prevent null arrays

  2. Tables Modified
    - movies
    - series
    - games
    - softwares
    - musics
    - places
    - books
    - companies
*/

-- Update movies table
ALTER TABLE movies 
  ALTER COLUMN genres SET DEFAULT '{}',
  ALTER COLUMN genres SET NOT NULL;

UPDATE movies SET genres = '{}' WHERE genres IS NULL;

-- Update series table
ALTER TABLE series 
  ALTER COLUMN genres SET DEFAULT '{}',
  ALTER COLUMN episode_runtime SET DEFAULT '{}',
  ALTER COLUMN genres SET NOT NULL,
  ALTER COLUMN episode_runtime SET NOT NULL;

UPDATE series SET genres = '{}' WHERE genres IS NULL;
UPDATE series SET episode_runtime = '{}' WHERE episode_runtime IS NULL;

-- Update games table
ALTER TABLE games 
  ALTER COLUMN genres SET DEFAULT '{}',
  ALTER COLUMN platforms SET DEFAULT '{}',
  ALTER COLUMN genres SET NOT NULL,
  ALTER COLUMN platforms SET NOT NULL;

UPDATE games SET genres = '{}' WHERE genres IS NULL;
UPDATE games SET platforms = '{}' WHERE platforms IS NULL;

-- Update softwares table
ALTER TABLE softwares 
  ALTER COLUMN platforms SET DEFAULT '{}',
  ALTER COLUMN platforms SET NOT NULL;

UPDATE softwares SET platforms = '{}' WHERE platforms IS NULL;

-- Update musics table
ALTER TABLE musics 
  ALTER COLUMN genres SET DEFAULT '{}',
  ALTER COLUMN genres SET NOT NULL;

UPDATE musics SET genres = '{}' WHERE genres IS NULL;

-- Update places table
ALTER TABLE places 
  ALTER COLUMN categories SET DEFAULT '{}',
  ALTER COLUMN photos SET DEFAULT '{}',
  ALTER COLUMN categories SET NOT NULL,
  ALTER COLUMN photos SET NOT NULL;

UPDATE places SET categories = '{}' WHERE categories IS NULL;
UPDATE places SET photos = '{}' WHERE photos IS NULL;

-- Update books table
ALTER TABLE books 
  ALTER COLUMN genres SET DEFAULT '{}',
  ALTER COLUMN genres SET NOT NULL;

UPDATE books SET genres = '{}' WHERE genres IS NULL;

-- Update companies table
ALTER TABLE companies 
  ALTER COLUMN company_type SET DEFAULT '{}',
  ALTER COLUMN company_type SET NOT NULL;

UPDATE companies SET company_type = '{}' WHERE company_type IS NULL;