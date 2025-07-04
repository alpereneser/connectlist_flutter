-- ===================================
-- CONNECTLIST SOCIAL FEATURES MIGRATIONS
-- ===================================

-- 1. Add missing fields to existing tables
-- ===================================

-- Add followers/following counts to users_profiles
ALTER TABLE public.users_profiles 
ADD COLUMN IF NOT EXISTS followers_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS lists_count INTEGER DEFAULT 0;

-- Add social fields to lists table
ALTER TABLE public.lists 
ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS tags TEXT[];

-- 2. Create new tables for additional social features
-- ===================================

-- User activity/analytics table
CREATE TABLE IF NOT EXISTS public.user_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- 'like', 'comment', 'follow', 'create_list', 'view_list'
    target_id UUID, -- ID of the target (list_id, user_id, etc.)
    target_type VARCHAR(50), -- 'list', 'user', 'comment'
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- List views tracking
CREATE TABLE IF NOT EXISTS public.list_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users_profiles(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- List shares tracking
CREATE TABLE IF NOT EXISTS public.list_shares (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL, -- 'twitter', 'facebook', 'whatsapp', 'copy_link'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User discovery/recommendations
CREATE TABLE IF NOT EXISTS public.user_recommendations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    recommended_user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    score DECIMAL(3,2) DEFAULT 0.0, -- 0.0 to 1.0 recommendation score
    reason VARCHAR(100), -- 'mutual_followers', 'similar_interests', 'location', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_user_recommendation UNIQUE(user_id, recommended_user_id)
);

-- 3. Create indexes for performance
-- ===================================

-- User activities indexes
CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON public.user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_type ON public.user_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activities_target ON public.user_activities(target_id, target_type);
CREATE INDEX IF NOT EXISTS idx_user_activities_created_at ON public.user_activities(created_at DESC);

-- List views indexes
CREATE INDEX IF NOT EXISTS idx_list_views_list_id ON public.list_views(list_id);
CREATE INDEX IF NOT EXISTS idx_list_views_user_id ON public.list_views(user_id);
CREATE INDEX IF NOT EXISTS idx_list_views_created_at ON public.list_views(created_at DESC);

-- Prevent multiple views from same user for same list (simpler approach)
-- This will be handled at application level for daily uniqueness
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_list_views_user_unique 
-- ON public.list_views(list_id, user_id) 
-- WHERE user_id IS NOT NULL;

-- List shares indexes
CREATE INDEX IF NOT EXISTS idx_list_shares_list_id ON public.list_shares(list_id);
CREATE INDEX IF NOT EXISTS idx_list_shares_user_id ON public.list_shares(user_id);

-- User recommendations indexes
CREATE INDEX IF NOT EXISTS idx_user_recommendations_user_id ON public.user_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_recommendations_score ON public.user_recommendations(score DESC);

-- Existing table indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_follows_follower_id ON public.user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following_id ON public.user_follows(following_id);
CREATE INDEX IF NOT EXISTS idx_list_likes_user_id ON public.list_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_list_likes_list_id ON public.list_likes(list_id);
CREATE INDEX IF NOT EXISTS idx_list_comments_list_id ON public.list_comments(list_id);
CREATE INDEX IF NOT EXISTS idx_list_comments_user_id ON public.list_comments(user_id);

-- 4. Create triggers for automatic counter updates
-- ===================================

-- Function to update user counts
CREATE OR REPLACE FUNCTION update_user_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Update follower count for followed user
        UPDATE public.users_profiles 
        SET followers_count = followers_count + 1
        WHERE id = NEW.following_id;
        
        -- Update following count for follower user
        UPDATE public.users_profiles 
        SET following_count = following_count + 1
        WHERE id = NEW.follower_id;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Update follower count for followed user
        UPDATE public.users_profiles 
        SET followers_count = GREATEST(followers_count - 1, 0)
        WHERE id = OLD.following_id;
        
        -- Update following count for follower user
        UPDATE public.users_profiles 
        SET following_count = GREATEST(following_count - 1, 0)
        WHERE id = OLD.follower_id;
        
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to update list counts
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

-- Function to update user list count
CREATE OR REPLACE FUNCTION update_user_list_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.users_profiles 
        SET lists_count = lists_count + 1
        WHERE id = NEW.creator_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.users_profiles 
        SET lists_count = GREATEST(lists_count - 1, 0)
        WHERE id = OLD.creator_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to track user activities
CREATE OR REPLACE FUNCTION track_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.user_activities (user_id, activity_type, target_id, target_type, metadata)
        VALUES (
            CASE TG_TABLE_NAME
                WHEN 'user_follows' THEN NEW.follower_id
                WHEN 'lists' THEN NEW.creator_id
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

-- 5. Create triggers
-- ===================================

-- User follow triggers
DROP TRIGGER IF EXISTS user_follows_count_trigger ON public.user_follows;
CREATE TRIGGER user_follows_count_trigger
    AFTER INSERT OR DELETE ON public.user_follows
    FOR EACH ROW EXECUTE FUNCTION update_user_counts();

-- List interaction triggers
DROP TRIGGER IF EXISTS list_likes_count_trigger ON public.list_likes;
CREATE TRIGGER list_likes_count_trigger
    AFTER INSERT OR DELETE ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION update_list_counts();

DROP TRIGGER IF EXISTS list_comments_count_trigger ON public.list_comments;
CREATE TRIGGER list_comments_count_trigger
    AFTER INSERT OR DELETE ON public.list_comments
    FOR EACH ROW EXECUTE FUNCTION update_list_counts();

DROP TRIGGER IF EXISTS list_shares_count_trigger ON public.list_shares;
CREATE TRIGGER list_shares_count_trigger
    AFTER INSERT OR DELETE ON public.list_shares
    FOR EACH ROW EXECUTE FUNCTION update_list_counts();

-- User list count trigger
DROP TRIGGER IF EXISTS user_list_count_trigger ON public.lists;
CREATE TRIGGER user_list_count_trigger
    AFTER INSERT OR DELETE ON public.lists
    FOR EACH ROW EXECUTE FUNCTION update_user_list_count();

-- Activity tracking triggers
DROP TRIGGER IF EXISTS track_follows_activity ON public.user_follows;
CREATE TRIGGER track_follows_activity
    AFTER INSERT ON public.user_follows
    FOR EACH ROW EXECUTE FUNCTION track_user_activity();

DROP TRIGGER IF EXISTS track_likes_activity ON public.list_likes;
CREATE TRIGGER track_likes_activity
    AFTER INSERT ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION track_user_activity();

DROP TRIGGER IF EXISTS track_comments_activity ON public.list_comments;
CREATE TRIGGER track_comments_activity
    AFTER INSERT ON public.list_comments
    FOR EACH ROW EXECUTE FUNCTION track_user_activity();

DROP TRIGGER IF EXISTS track_shares_activity ON public.list_shares;
CREATE TRIGGER track_shares_activity
    AFTER INSERT ON public.list_shares
    FOR EACH ROW EXECUTE FUNCTION track_user_activity();

-- 6. Initialize existing data counts (run once)
-- ===================================

-- Update existing user followers/following counts
UPDATE public.users_profiles 
SET followers_count = (
    SELECT COUNT(*) FROM public.user_follows 
    WHERE following_id = users_profiles.id
),
following_count = (
    SELECT COUNT(*) FROM public.user_follows 
    WHERE follower_id = users_profiles.id
),
lists_count = (
    SELECT COUNT(*) FROM public.lists 
    WHERE creator_id = users_profiles.id
);

-- Update existing list counts
UPDATE public.lists 
SET likes_count = (
    SELECT COUNT(*) FROM public.list_likes 
    WHERE list_id = lists.id
),
comments_count = (
    SELECT COUNT(*) FROM public.list_comments 
    WHERE list_id = lists.id
);

-- 7. Enable Row Level Security (RLS) for new tables
-- ===================================

ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_recommendations ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- User activities: users can see their own activities, others can see public activities
CREATE POLICY "Users can view their own activities" ON public.user_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activities" ON public.user_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- List views: anyone can view, only authenticated users can insert
CREATE POLICY "Anyone can view list views" ON public.list_views
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can track views" ON public.list_views
    FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() IS NOT NULL);

-- List shares: users can see shares, only authenticated users can insert
CREATE POLICY "Users can view list shares" ON public.list_shares
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can share lists" ON public.list_shares
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User recommendations: users can see their own recommendations
CREATE POLICY "Users can view their recommendations" ON public.user_recommendations
    FOR SELECT USING (auth.uid() = user_id);

-- ===================================
-- MIGRATION COMPLETE
-- ===================================

-- Summary of what this migration adds:
-- 1. User follower/following/lists counts
-- 2. List views/shares/featured status
-- 3. User activity tracking
-- 4. List views analytics
-- 5. Social sharing tracking
-- 6. User recommendation system
-- 7. Automatic counter updates via triggers
-- 8. Performance indexes
-- 9. Row Level Security policies