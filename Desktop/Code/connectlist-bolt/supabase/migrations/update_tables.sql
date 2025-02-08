-- First, let's create a backup of the existing lists table
CREATE TABLE IF NOT EXISTS lists_backup AS SELECT * FROM lists;

-- Drop the existing lists table
DROP TABLE IF EXISTS lists;

-- Recreate the lists table with all required columns
CREATE TABLE public.lists (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    description text,
    category text NOT NULL,
    items jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    user_id uuid REFERENCES auth.users NOT NULL,
    comments_count integer DEFAULT 0,
    likes_count integer DEFAULT 0,
    saves_count integer DEFAULT 0
);

-- Restore data from backup if it exists
INSERT INTO lists (id, title, description, category, items, created_at, user_id, comments_count, likes_count, saves_count)
SELECT 
    id,
    name as title,  -- assuming the old column was called 'name', adjust if different
    description,
    'unknown' as category,  -- default category for old data
    '[]'::jsonb as items,
    created_at,
    user_id,
    0 as comments_count,
    0 as likes_count,
    0 as saves_count
FROM lists_backup;

-- Set up RLS
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view all lists"
    ON public.lists FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can create their own lists"
    ON public.lists FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own lists"
    ON public.lists FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own lists"
    ON public.lists FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS lists_user_id_idx ON public.lists(user_id);
CREATE INDEX IF NOT EXISTS lists_category_idx ON public.lists(category);
CREATE INDEX IF NOT EXISTS lists_created_at_idx ON public.lists(created_at DESC);

-- Create notifications table with proper foreign key relationships
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users NOT NULL,
    from_user_id uuid REFERENCES auth.users,
    type text NOT NULL,
    content text,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add foreign key relationship to profiles
ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_from_user_id_fkey 
    FOREIGN KEY (from_user_id) 
    REFERENCES auth.users(id)
    ON DELETE CASCADE;

-- Set up RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create policies for notifications
CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create notifications"
    ON public.notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Create indexes for notifications
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.notifications(created_at DESC);
