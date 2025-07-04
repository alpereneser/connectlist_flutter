-- Debug triggers and check for any remaining "follower_id" references

-- 1. Check all triggers on list_likes table
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'list_likes';

-- 2. Check the current trigger functions
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name IN ('update_list_counts', 'track_user_activity');

-- 3. Force recreate the trigger functions to ensure they use correct column names
CREATE OR REPLACE FUNCTION update_list_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Add detailed logging
    RAISE NOTICE 'update_list_counts triggered for table: %, operation: %', TG_TABLE_NAME, TG_OP;
    
    IF TG_OP = 'INSERT' THEN
        RAISE NOTICE 'INSERT operation - NEW record: %', NEW;
        
        IF TG_TABLE_NAME = 'list_likes' THEN
            UPDATE public.lists 
            SET likes_count = COALESCE(likes_count, 0) + 1
            WHERE id = NEW.list_id;
            RAISE NOTICE 'Incremented likes_count for list_id: %', NEW.list_id;
        ELSIF TG_TABLE_NAME = 'list_comments' THEN
            UPDATE public.lists 
            SET comments_count = COALESCE(comments_count, 0) + 1
            WHERE id = NEW.list_id;
        ELSIF TG_TABLE_NAME = 'list_shares' THEN
            UPDATE public.lists 
            SET shares_count = COALESCE(shares_count, 0) + 1
            WHERE id = NEW.list_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        RAISE NOTICE 'DELETE operation - OLD record: %', OLD;
        
        IF TG_TABLE_NAME = 'list_likes' THEN
            UPDATE public.lists 
            SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0)
            WHERE id = OLD.list_id;
            RAISE NOTICE 'Decremented likes_count for list_id: %', OLD.list_id;
        ELSIF TG_TABLE_NAME = 'list_comments' THEN
            UPDATE public.lists 
            SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0)
            WHERE id = OLD.list_id;
        ELSIF TG_TABLE_NAME = 'list_shares' THEN
            UPDATE public.lists 
            SET shares_count = GREATEST(COALESCE(shares_count, 0) - 1, 0)
            WHERE id = OLD.list_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION track_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Add detailed logging
    RAISE NOTICE 'track_user_activity triggered for table: %, operation: %', TG_TABLE_NAME, TG_OP;
    
    IF TG_OP = 'INSERT' THEN
        RAISE NOTICE 'INSERT operation - NEW record: %', NEW;
        
        -- Determine user_id based on table
        DECLARE
            activity_user_id UUID;
            activity_type TEXT;
            target_id UUID;
            target_type TEXT;
        BEGIN
            CASE TG_TABLE_NAME
                WHEN 'user_follows' THEN 
                    activity_user_id := NEW.follower_id;
                    activity_type := 'follow';
                    target_id := NEW.following_id;
                    target_type := 'user';
                WHEN 'lists' THEN 
                    activity_user_id := NEW.creator_id;
                    activity_type := 'create_list';
                    target_id := NEW.id;
                    target_type := 'list';
                WHEN 'list_likes' THEN 
                    activity_user_id := NEW.user_id;  -- Use user_id for list_likes
                    activity_type := 'like';
                    target_id := NEW.list_id;
                    target_type := 'list';
                WHEN 'list_comments' THEN 
                    activity_user_id := NEW.user_id;
                    activity_type := 'comment';
                    target_id := NEW.list_id;
                    target_type := 'list';
                WHEN 'list_shares' THEN 
                    activity_user_id := NEW.user_id;
                    activity_type := 'share';
                    target_id := NEW.list_id;
                    target_type := 'list';
                ELSE
                    RAISE NOTICE 'Unknown table for activity tracking: %', TG_TABLE_NAME;
                    RETURN NEW;
            END CASE;
            
            RAISE NOTICE 'Inserting activity: user_id=%, type=%, target_id=%, target_type=%', 
                activity_user_id, activity_type, target_id, target_type;
            
            INSERT INTO public.user_activities (user_id, activity_type, target_id, target_type, metadata)
            VALUES (activity_user_id, activity_type, target_id, target_type, '{}'::jsonb);
            
        END;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Drop and recreate triggers to ensure they use the updated functions
DROP TRIGGER IF EXISTS list_likes_count_trigger ON public.list_likes;
DROP TRIGGER IF EXISTS track_likes_activity ON public.list_likes;

CREATE TRIGGER list_likes_count_trigger
    AFTER INSERT OR DELETE ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION update_list_counts();

CREATE TRIGGER track_likes_activity
    AFTER INSERT ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION track_user_activity();

-- 5. Test the setup
SELECT 'Triggers recreated successfully' as status;