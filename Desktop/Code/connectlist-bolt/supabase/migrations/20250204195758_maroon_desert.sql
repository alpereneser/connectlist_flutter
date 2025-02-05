/*
  # Create Content Database Schema

  1. New Tables
    - categories (with predefined content categories)
    - content_types (for people roles)
    - content_base (common fields)
    - people, movies, series, games, softwares, musics, places, books, companies
    - Junction tables: content_people, content_companies, people_content_types

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Create indexes for better performance
*/

-- Create enum for content categories
CREATE TYPE content_category AS ENUM (
  'movies',
  'series',
  'people',
  'games',
  'softwares',
  'musics',
  'places',
  'books',
  'companies'
);

-- Create enum for status
CREATE TYPE content_status AS ENUM (
  'draft',
  'published',
  'archived'
);

-- Create categories table
CREATE TABLE categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name content_category NOT NULL,
  display_name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Insert default categories
INSERT INTO categories (name, display_name, description) VALUES
  ('movies', 'Movies', 'Film and cinema content'),
  ('series', 'TV Series', 'Television series and shows'),
  ('people', 'People', 'Individuals in various roles'),
  ('games', 'Games', 'Video and computer games'),
  ('softwares', 'Software', 'Software applications and tools'),
  ('musics', 'Music', 'Musical content and audio'),
  ('places', 'Places', 'Locations and venues'),
  ('books', 'Books', 'Literary works and publications'),
  ('companies', 'Companies', 'Organizations and businesses');

-- Create content_types table for people roles
CREATE TABLE content_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid REFERENCES categories(id),
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Insert default content types
INSERT INTO content_types (category_id, name, description) 
SELECT id, 'Actor', 'Performs in movies and series'
FROM categories WHERE name = 'people';

INSERT INTO content_types (category_id, name, description)
SELECT id, 'Author', 'Writes books or other content'
FROM categories WHERE name = 'people';

INSERT INTO content_types (category_id, name, description)
SELECT id, 'Athlete', 'Professional sports person'
FROM categories WHERE name = 'people';

INSERT INTO content_types (category_id, name, description)
SELECT id, 'Director', 'Directs movies or series'
FROM categories WHERE name = 'people';

INSERT INTO content_types (category_id, name, description)
SELECT id, 'Musician', 'Creates or performs music'
FROM categories WHERE name = 'people';

INSERT INTO content_types (category_id, name, description)
SELECT id, 'Developer', 'Develops software or games'
FROM categories WHERE name = 'people';

-- Create base table for common fields
CREATE TABLE content_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL REFERENCES categories(id),
  title text NOT NULL,
  description text,
  status content_status DEFAULT 'draft',
  cover_image_url text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create people table (without content_types array)
CREATE TABLE people (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  biography text,
  birth_date date,
  death_date date,
  nationality text,
  website text,
  social_media jsonb,
  profile_image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create people_content_types junction table
CREATE TABLE people_content_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  content_type_id uuid NOT NULL REFERENCES content_types(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(person_id, content_type_id)
);

-- Create movies table
CREATE TABLE movies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  original_title text,
  tagline text,
  overview text,
  release_date date,
  runtime integer,
  budget numeric,
  revenue numeric,
  genres text[],
  poster_path text,
  backdrop_path text,
  tmdb_id integer,
  imdb_id text,
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create series table
CREATE TABLE series (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  original_title text,
  tagline text,
  overview text,
  first_air_date date,
  last_air_date date,
  number_of_seasons integer,
  number_of_episodes integer,
  episode_runtime integer[],
  genres text[],
  poster_path text,
  backdrop_path text,
  tmdb_id integer,
  imdb_id text,
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create games table
CREATE TABLE games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  release_date date,
  genres text[],
  platforms text[],
  developer text,
  publisher text,
  website text,
  cover_image_url text,
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create softwares table
CREATE TABLE softwares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  version text,
  release_date date,
  category text,
  platforms text[],
  website text,
  repository_url text,
  logo_url text,
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create musics table
CREATE TABLE musics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  album text,
  release_date date,
  duration interval,
  genres text[],
  lyrics text,
  cover_art_url text,
  spotify_id text,
  apple_music_id text,
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create places table
CREATE TABLE places (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  address text,
  city text,
  country text,
  latitude numeric,
  longitude numeric,
  categories text[],
  website text,
  phone text,
  photos text[],
  google_place_id text,
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create books table
CREATE TABLE books (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  original_title text,
  description text,
  isbn text,
  publication_date date,
  publisher text,
  genres text[],
  language text,
  page_count integer,
  cover_image_url text,
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create companies table
CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  founding_date date,
  website text,
  headquarters_address text,
  logo_url text,
  company_type text[], -- Publisher, Production Company, Software Company, etc.
  status content_status DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create junction table for content-people relationships
CREATE TABLE content_people (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id uuid NOT NULL,
  person_id uuid NOT NULL REFERENCES people(id),
  content_type_id uuid NOT NULL REFERENCES content_types(id),
  role text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create junction table for content-company relationships
CREATE TABLE content_companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id uuid NOT NULL,
  company_id uuid NOT NULL REFERENCES companies(id),
  relationship_type text NOT NULL, -- Publisher, Producer, Developer, etc.
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE people_content_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE movies ENABLE ROW LEVEL SECURITY;
ALTER TABLE series ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE softwares ENABLE ROW LEVEL SECURITY;
ALTER TABLE musics ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_people ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_companies ENABLE ROW LEVEL SECURITY;

-- Create policies for each table
CREATE POLICY "Enable read access for authenticated users" ON categories
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON content_types
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON content_base
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON people
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON people_content_types
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON movies
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON series
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON games
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON softwares
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON musics
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON places
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON books
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON companies
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON content_people
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable read access for authenticated users" ON content_companies
  FOR SELECT TO authenticated USING (true);

-- Create indexes for better performance
CREATE INDEX idx_movies_title ON movies(title);
CREATE INDEX idx_series_title ON series(title);
CREATE INDEX idx_people_full_name ON people(full_name);
CREATE INDEX idx_games_title ON games(title);
CREATE INDEX idx_softwares_name ON softwares(name);
CREATE INDEX idx_musics_title ON musics(title);
CREATE INDEX idx_places_name ON places(name);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_companies_name ON companies(name);
CREATE INDEX idx_people_content_types_person ON people_content_types(person_id);
CREATE INDEX idx_people_content_types_type ON people_content_types(content_type_id);