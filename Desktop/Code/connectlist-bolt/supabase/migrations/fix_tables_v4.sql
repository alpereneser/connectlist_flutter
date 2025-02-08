-- Drop all dependent objects with CASCADE
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.lists CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.follows CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Create profiles table first
CREATE TABLE public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username text UNIQUE,
    name text,
    avatar_url text,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Create trigger for new user profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, username, name, avatar_url)
    VALUES (
        new.id,
        new.raw_user_meta_data->>'username',
        new.raw_user_meta_data->>'name',
        new.raw_user_meta_data->>'avatar_url'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create lists table
CREATE TABLE public.lists (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    description text,
    category text NOT NULL,
    items jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    comments_count integer DEFAULT 0,
    likes_count integer DEFAULT 0,
    saves_count integer DEFAULT 0
);

-- Enable RLS for lists
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;

-- Create lists policies
CREATE POLICY "Users can view all lists" ON public.lists
    FOR SELECT USING (true);

CREATE POLICY "Users can insert own lists" ON public.lists
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own lists" ON public.lists
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own lists" ON public.lists
    FOR DELETE USING (auth.uid() = user_id);

-- Create notifications table
CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    from_user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    type text NOT NULL,
    content text,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create notifications policies
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- Create follows table
CREATE TABLE public.follows (
    follower_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    following_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (follower_id, following_id)
);

-- Enable RLS for follows
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- Create follows policies
CREATE POLICY "Users can view all follows" ON public.follows
    FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON public.follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow" ON public.follows
    FOR DELETE USING (auth.uid() = follower_id);

-- Create messages table
CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    content text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    read boolean DEFAULT false
);

-- Enable RLS for messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create messages policies
CREATE POLICY "Users can view their messages" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Create messages_participants view
CREATE OR REPLACE VIEW public.messages_participants AS
SELECT DISTINCT
    LEAST(sender_id, receiver_id) as user1_id,
    GREATEST(sender_id, receiver_id) as user2_id
FROM public.messages;

-- Create search_profiles function
CREATE OR REPLACE FUNCTION public.search_profiles(search_query text)
RETURNS TABLE (
    id uuid,
    username text,
    name text,
    avatar_url text
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.username,
        p.name,
        p.avatar_url
    FROM profiles p
    WHERE
        p.username ILIKE '%' || search_query || '%'
        OR p.name ILIKE '%' || search_query || '%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles(username);
CREATE INDEX IF NOT EXISTS lists_user_id_idx ON public.lists(user_id);
CREATE INDEX IF NOT EXISTS lists_category_idx ON public.lists(category);
CREATE INDEX IF NOT EXISTS lists_created_at_idx ON public.lists(created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS notifications_from_user_id_idx ON public.notifications(from_user_id);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_receiver_id_idx ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON public.messages(created_at DESC);

-- Insert existing users into profiles
INSERT INTO public.profiles (id, username, name, avatar_url)
SELECT 
    id,
    raw_user_meta_data->>'username',
    raw_user_meta_data->>'name',
    raw_user_meta_data->>'avatar_url'
FROM auth.users
ON CONFLICT (id) DO NOTHING;
