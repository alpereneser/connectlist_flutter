-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    name text,
    username text UNIQUE,
    avatar_url text,
    full_name text,
    updated_at timestamp with time zone
);

-- Enable RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create trigger to handle new user profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, name, avatar_url, username)
    VALUES (new.id, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'username');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Recreate lists table
DROP TABLE IF EXISTS public.lists;
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

-- Enable RLS for lists
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;

-- Lists policies
CREATE POLICY "Users can view all lists" ON public.lists
    FOR SELECT USING (true);

CREATE POLICY "Users can create their own lists" ON public.lists
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own lists" ON public.lists
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own lists" ON public.lists
    FOR DELETE USING (auth.uid() = user_id);

-- Create notifications table
DROP TABLE IF EXISTS public.notifications;
CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users NOT NULL,
    from_user_id uuid REFERENCES auth.users ON DELETE SET NULL,
    type text NOT NULL,
    content text,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles(username);
CREATE INDEX IF NOT EXISTS lists_user_id_idx ON public.lists(user_id);
CREATE INDEX IF NOT EXISTS lists_category_idx ON public.lists(category);
CREATE INDEX IF NOT EXISTS lists_created_at_idx ON public.lists(created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS notifications_from_user_id_idx ON public.notifications(from_user_id);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.notifications(created_at DESC);

-- Update ListDetails.vue query to use proper join
COMMENT ON TABLE public.lists IS 'User created lists';
COMMENT ON TABLE public.profiles IS 'User profile information';
COMMENT ON TABLE public.notifications IS 'User notifications';
