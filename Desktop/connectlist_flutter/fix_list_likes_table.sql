-- Fix list_likes table structure for beğeni hatası

-- Check existing table structure
DO $$
BEGIN
    -- Check if the table exists at all
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'list_likes' AND table_schema = 'public') THEN
        -- Create the table if it doesn't exist
        CREATE TABLE public.list_likes (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(list_id, user_id)  -- Prevent duplicate likes
        );
        RAISE NOTICE 'Created list_likes table';
    ELSE
        -- Check if user_id column exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'list_likes' AND column_name = 'user_id' AND table_schema = 'public') THEN
            -- Try to find a similar column (might be liker_id, follower_id, etc.)
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'list_likes' AND column_name = 'liker_id' AND table_schema = 'public') THEN
                ALTER TABLE public.list_likes RENAME COLUMN liker_id TO user_id;
                RAISE NOTICE 'Renamed liker_id to user_id';
            ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'list_likes' AND column_name = 'follower_id' AND table_schema = 'public') THEN
                ALTER TABLE public.list_likes RENAME COLUMN follower_id TO user_id;
                RAISE NOTICE 'Renamed follower_id to user_id';
            ELSE
                -- Add the user_id column
                ALTER TABLE public.list_likes ADD COLUMN user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE;
                RAISE NOTICE 'Added user_id column to list_likes';
            END IF;
        ELSE
            RAISE NOTICE 'user_id column already exists in list_likes';
        END IF;
    END IF;
END $$;

-- Ensure proper indexes
CREATE INDEX IF NOT EXISTS idx_list_likes_user_id ON public.list_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_list_likes_list_id ON public.list_likes(list_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_list_likes_unique ON public.list_likes(list_id, user_id);

-- Enable RLS if not already enabled
ALTER TABLE public.list_likes ENABLE ROW LEVEL SECURITY;

-- Update RLS policies
DROP POLICY IF EXISTS "Users can manage their own likes" ON public.list_likes;
DROP POLICY IF EXISTS "Users can view likes" ON public.list_likes;
DROP POLICY IF EXISTS "Users can like lists" ON public.list_likes;

-- Policy for viewing likes (anyone can see which lists are liked)
CREATE POLICY "Anyone can view likes" ON public.list_likes
    FOR SELECT USING (true);

-- Policy for inserting likes (only authenticated users can like)
CREATE POLICY "Users can like lists" ON public.list_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for deleting likes (users can only remove their own likes)
CREATE POLICY "Users can remove their own likes" ON public.list_likes
    FOR DELETE USING (auth.uid() = user_id);

-- Fix the trigger function to handle the correct column name
CREATE OR REPLACE FUNCTION update_list_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF TG_TABLE_NAME = 'list_likes' THEN
            UPDATE public.lists 
            SET likes_count = likes_count + 1
            WHERE id = NEW.list_id;
        ELSIF TG_TABLE_NAME = 'list_comments' THEN
            UPDATE public.lists 
            SET comments_count = comments_count + 1
            WHERE id = NEW.list_id;
        ELSIF TG_TABLE_NAME = 'list_shares' THEN
            UPDATE public.lists 
            SET shares_count = shares_count + 1
            WHERE id = NEW.list_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF TG_TABLE_NAME = 'list_likes' THEN
            UPDATE public.lists 
            SET likes_count = GREATEST(likes_count - 1, 0)
            WHERE id = OLD.list_id;
        ELSIF TG_TABLE_NAME = 'list_comments' THEN
            UPDATE public.lists 
            SET comments_count = GREATEST(comments_count - 1, 0)
            WHERE id = OLD.list_id;
        ELSIF TG_TABLE_NAME = 'list_shares' THEN
            UPDATE public.lists 
            SET shares_count = GREATEST(shares_count - 1, 0)
            WHERE id = OLD.list_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Fix the activity tracking trigger function  
CREATE OR REPLACE FUNCTION track_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.user_activities (user_id, activity_type, target_id, target_type, metadata)
        VALUES (
            CASE TG_TABLE_NAME
                WHEN 'user_follows' THEN NEW.follower_id
                WHEN 'lists' THEN NEW.creator_id
                WHEN 'list_likes' THEN NEW.user_id  -- Use user_id here
                WHEN 'list_comments' THEN NEW.user_id
                WHEN 'list_shares' THEN NEW.user_id
                ELSE NEW.user_id
            END,
            CASE TG_TABLE_NAME
                WHEN 'user_follows' THEN 'follow'
                WHEN 'list_likes' THEN 'like'
                WHEN 'list_comments' THEN 'comment'
                WHEN 'list_shares' THEN 'share'
                WHEN 'lists' THEN 'create_list'
            END,
            CASE TG_TABLE_NAME
                WHEN 'user_follows' THEN NEW.following_id
                WHEN 'list_likes' THEN NEW.list_id
                WHEN 'list_comments' THEN NEW.list_id
                WHEN 'list_shares' THEN NEW.list_id
                WHEN 'lists' THEN NEW.id
            END,
            CASE TG_TABLE_NAME
                WHEN 'user_follows' THEN 'user'
                WHEN 'lists' THEN 'list'
                ELSE 'list'
            END,
            '{}'::jsonb
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers to ensure they use the updated functions
DROP TRIGGER IF EXISTS list_likes_count_trigger ON public.list_likes;
CREATE TRIGGER list_likes_count_trigger
    AFTER INSERT OR DELETE ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION update_list_counts();

DROP TRIGGER IF EXISTS track_likes_activity ON public.list_likes;
CREATE TRIGGER track_likes_activity
    AFTER INSERT ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION track_user_activity();

-- Initialize likes count for existing lists
UPDATE public.lists 
SET likes_count = (
    SELECT COUNT(*) FROM public.list_likes 
    WHERE list_id = lists.id
) WHERE likes_count IS NULL;

-- Debug info
SELECT 'list_likes table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'list_likes' 
AND table_schema = 'public'
ORDER BY ordinal_position;