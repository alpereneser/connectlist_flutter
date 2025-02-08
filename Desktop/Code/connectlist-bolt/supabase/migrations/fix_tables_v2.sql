-- First handle the lists table
DROP TABLE IF EXISTS lists_backup;
CREATE TABLE lists_backup AS SELECT * FROM lists;
DROP TABLE IF EXISTS lists;

-- Recreate lists table with correct schema
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

-- Restore data from backup
INSERT INTO lists (id, title, description, category, items, created_at, user_id, comments_count, likes_count, saves_count)
SELECT 
    id,
    name as title,
    description,
    'unknown' as category,
    '[]'::jsonb as items,
    created_at,
    user_id,
    0, 0, 0
FROM lists_backup;

-- Set up RLS for lists
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;

-- Create policies for lists
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

-- Create indexes for lists
CREATE INDEX IF NOT EXISTS lists_user_id_idx ON public.lists(user_id);
CREATE INDEX IF NOT EXISTS lists_category_idx ON public.lists(category);
CREATE INDEX IF NOT EXISTS lists_created_at_idx ON public.lists(created_at DESC);

-- Now handle the notifications table
DROP TABLE IF EXISTS public.notifications;

-- Create notifications table
CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users NOT NULL,
    content text,
    type text NOT NULL,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    from_user_id uuid REFERENCES auth.users ON DELETE SET NULL
);

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
CREATE INDEX IF NOT EXISTS notifications_from_user_id_idx ON public.notifications(from_user_id);
