-- ConnectList Complete Database Schema (FIXED)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users_profiles table
CREATE TABLE IF NOT EXISTS public.users_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    icon TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Insert default categories
INSERT INTO public.categories (name, display_name, icon) VALUES
    ('books', 'Books', 'book'),
    ('movies', 'Movies', 'movie'),
    ('tv_shows', 'TV Shows', 'tv'),
    ('games', 'Games', 'game'),
    ('places', 'Places', 'place')
ON CONFLICT (name) DO NOTHING;

-- Create lists table
CREATE TABLE IF NOT EXISTS public.lists (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    creator_id UUID REFERENCES public.users_profiles(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES public.categories(id) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    privacy TEXT DEFAULT 'public' CHECK (privacy IN ('public', 'private', 'friends')),
    cover_image_url TEXT,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create list_items table
CREATE TABLE IF NOT EXISTS public.list_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    list_id UUID REFERENCES public.lists(id) ON DELETE CASCADE NOT NULL,
    external_id TEXT,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    external_data JSONB,
    user_note TEXT,
    position INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create list_likes table
CREATE TABLE IF NOT EXISTS public.list_likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users_profiles(id) ON DELETE CASCADE NOT NULL,
    list_id UUID REFERENCES public.lists(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(user_id, list_id)
);

-- Create list_comments table
CREATE TABLE IF NOT EXISTS public.list_comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users_profiles(id) ON DELETE CASCADE NOT NULL,
    list_id UUID REFERENCES public.lists(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create user_follows table
CREATE TABLE IF NOT EXISTS public.user_follows (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    follower_id UUID REFERENCES public.users_profiles(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES public.users_profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- Create indexes for better performance
CREATE INDEX idx_lists_creator_id ON public.lists(creator_id);
CREATE INDEX idx_lists_category_id ON public.lists(category_id);
CREATE INDEX idx_list_items_list_id ON public.list_items(list_id);
CREATE INDEX idx_list_likes_user_id ON public.list_likes(user_id);
CREATE INDEX idx_list_likes_list_id ON public.list_likes(list_id);
CREATE INDEX idx_list_comments_list_id ON public.list_comments(list_id);
CREATE INDEX idx_user_follows_follower_id ON public.user_follows(follower_id);
CREATE INDEX idx_user_follows_following_id ON public.user_follows(following_id);

-- Enable Row Level Security
ALTER TABLE public.users_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.users_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.users_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Categories policies (read-only for all authenticated users)
CREATE POLICY "Categories are viewable by everyone" ON public.categories
    FOR SELECT USING (true);

-- Lists policies
CREATE POLICY "Public lists are viewable by everyone" ON public.lists
    FOR SELECT USING (privacy = 'public' OR creator_id = auth.uid());

CREATE POLICY "Users can create lists" ON public.lists
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update own lists" ON public.lists
    FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Users can delete own lists" ON public.lists
    FOR DELETE USING (auth.uid() = creator_id);

-- List items policies
CREATE POLICY "List items viewable if list is viewable" ON public.list_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.lists
            WHERE lists.id = list_items.list_id
            AND (lists.privacy = 'public' OR lists.creator_id = auth.uid())
        )
    );

CREATE POLICY "Users can manage items in own lists" ON public.list_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.lists
            WHERE lists.id = list_items.list_id
            AND lists.creator_id = auth.uid()
        )
    );

-- List likes policies
CREATE POLICY "Likes are viewable by everyone" ON public.list_likes
    FOR SELECT USING (true);

CREATE POLICY "Users can like lists" ON public.list_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike lists" ON public.list_likes
    FOR DELETE USING (auth.uid() = user_id);

-- List comments policies
CREATE POLICY "Comments are viewable by everyone" ON public.list_comments
    FOR SELECT USING (true);

CREATE POLICY "Users can create comments" ON public.list_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON public.list_comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON public.list_comments
    FOR DELETE USING (auth.uid() = user_id);

-- User follows policies
CREATE POLICY "Follows are viewable by everyone" ON public.user_follows
    FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON public.user_follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others" ON public.user_follows
    FOR DELETE USING (auth.uid() = follower_id);

-- Create functions

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.users_profiles (id, username, full_name, avatar_url)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
        COALESCE(new.raw_user_meta_data->>'full_name', ''),
        COALESCE(new.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update likes count
CREATE OR REPLACE FUNCTION public.update_likes_count()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.lists
        SET likes_count = likes_count + 1
        WHERE id = NEW.list_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.lists
        SET likes_count = likes_count - 1
        WHERE id = OLD.list_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update likes count
CREATE OR REPLACE TRIGGER update_list_likes_count
    AFTER INSERT OR DELETE ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION public.update_likes_count();

-- Function to update comments count
CREATE OR REPLACE FUNCTION public.update_comments_count()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.lists
        SET comments_count = comments_count + 1
        WHERE id = NEW.list_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.lists
        SET comments_count = comments_count - 1
        WHERE id = OLD.list_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update comments count
CREATE OR REPLACE TRIGGER update_list_comments_count
    AFTER INSERT OR DELETE ON public.list_comments
    FOR EACH ROW EXECUTE FUNCTION public.update_comments_count();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update updated_at
CREATE OR REPLACE TRIGGER update_users_profiles_updated_at
    BEFORE UPDATE ON public.users_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE TRIGGER update_lists_updated_at
    BEFORE UPDATE ON public.lists
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE TRIGGER update_list_comments_updated_at
    BEFORE UPDATE ON public.list_comments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();