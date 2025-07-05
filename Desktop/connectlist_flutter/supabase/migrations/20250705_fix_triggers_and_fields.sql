-- Hataları düzelten ve eksik alanları ekleyen migration
-- 2025-07-05: Fix triggers and add missing fields

-- Önce mevcut trigger'ları kaldır
DROP TRIGGER IF EXISTS update_list_likes_count ON public.list_likes;
DROP TRIGGER IF EXISTS update_list_comments_count ON public.list_comments;
DROP TRIGGER IF EXISTS update_user_follows_count ON public.user_follows;

-- Önce mevcut fonksiyonları kaldır
DROP FUNCTION IF EXISTS public.update_likes_count();
DROP FUNCTION IF EXISTS public.update_comments_count();
DROP FUNCTION IF EXISTS public.update_follows_count();

-- lists tablosuna eksik alanları ekle
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0;
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0;
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS item_count INTEGER DEFAULT 0;
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS allow_comments BOOLEAN DEFAULT true;
ALTER TABLE public.lists ADD COLUMN IF NOT EXISTS allow_collaboration BOOLEAN DEFAULT false;

-- users_profiles tablosuna eksik alanları ekle
ALTER TABLE public.users_profiles ADD COLUMN IF NOT EXISTS followers_count INTEGER DEFAULT 0;
ALTER TABLE public.users_profiles ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0;
ALTER TABLE public.users_profiles ADD COLUMN IF NOT EXISTS lists_count INTEGER DEFAULT 0;
ALTER TABLE public.users_profiles ADD COLUMN IF NOT EXISTS push_notifications_enabled BOOLEAN DEFAULT true;

-- list_items tablosuna eksik alanları ekle
ALTER TABLE public.list_items ADD COLUMN IF NOT EXISTS content_id TEXT;
ALTER TABLE public.list_items ADD COLUMN IF NOT EXISTS content_type TEXT;
ALTER TABLE public.list_items ADD COLUMN IF NOT EXISTS subtitle TEXT;
ALTER TABLE public.list_items ADD COLUMN IF NOT EXISTS metadata JSONB;
ALTER TABLE public.list_items ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';

-- Yeni tablolar oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.list_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users_profiles(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.list_shares (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    platform VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndeksleri oluştur
CREATE INDEX IF NOT EXISTS idx_list_views_list_id ON public.list_views(list_id);
CREATE INDEX IF NOT EXISTS idx_list_views_user_id ON public.list_views(user_id);
CREATE INDEX IF NOT EXISTS idx_list_shares_list_id ON public.list_shares(list_id);
CREATE INDEX IF NOT EXISTS idx_list_shares_user_id ON public.list_shares(user_id);

-- Düzeltilmiş likes count fonksiyonu (follower_id hatası yok)
CREATE OR REPLACE FUNCTION public.update_likes_count()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.lists
        SET likes_count = likes_count + 1
        WHERE id = NEW.list_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.lists
        SET likes_count = GREATEST(0, likes_count - 1)
        WHERE id = OLD.list_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Düzeltilmiş comments count fonksiyonu
CREATE OR REPLACE FUNCTION public.update_comments_count()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.lists
        SET comments_count = comments_count + 1
        WHERE id = NEW.list_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.lists
        SET comments_count = GREATEST(0, comments_count - 1)
        WHERE id = OLD.list_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- User follows count fonksiyonu
CREATE OR REPLACE FUNCTION public.update_follows_count()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Takip edeni güncelle (following_count artır)
        UPDATE public.users_profiles
        SET following_count = following_count + 1
        WHERE id = NEW.follower_id;
        
        -- Takip edileni güncelle (followers_count artır)
        UPDATE public.users_profiles
        SET followers_count = followers_count + 1
        WHERE id = NEW.following_id;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Takip edeni güncelle (following_count azalt)
        UPDATE public.users_profiles
        SET following_count = GREATEST(0, following_count - 1)
        WHERE id = OLD.follower_id;
        
        -- Takip edileni güncelle (followers_count azalt)
        UPDATE public.users_profiles
        SET followers_count = GREATEST(0, followers_count - 1)
        WHERE id = OLD.following_id;
        
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Lists count fonksiyonu
CREATE OR REPLACE FUNCTION public.update_lists_count()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.users_profiles
        SET lists_count = lists_count + 1
        WHERE id = NEW.creator_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.users_profiles
        SET lists_count = GREATEST(0, lists_count - 1)
        WHERE id = OLD.creator_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Views count fonksiyonu
CREATE OR REPLACE FUNCTION public.update_views_count()
RETURNS trigger AS $$
BEGIN
    UPDATE public.lists
    SET views_count = views_count + 1
    WHERE id = NEW.list_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Shares count fonksiyonu  
CREATE OR REPLACE FUNCTION public.update_shares_count()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.lists
        SET shares_count = shares_count + 1
        WHERE id = NEW.list_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.lists
        SET shares_count = GREATEST(0, shares_count - 1)
        WHERE id = OLD.list_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları oluştur
CREATE TRIGGER update_list_likes_count
    AFTER INSERT OR DELETE ON public.list_likes
    FOR EACH ROW EXECUTE FUNCTION public.update_likes_count();

CREATE TRIGGER update_list_comments_count
    AFTER INSERT OR DELETE ON public.list_comments
    FOR EACH ROW EXECUTE FUNCTION public.update_comments_count();

CREATE TRIGGER update_user_follows_count
    AFTER INSERT OR DELETE ON public.user_follows
    FOR EACH ROW EXECUTE FUNCTION public.update_follows_count();

CREATE TRIGGER update_user_lists_count
    AFTER INSERT OR DELETE ON public.lists
    FOR EACH ROW EXECUTE FUNCTION public.update_lists_count();

CREATE TRIGGER update_list_views_count
    AFTER INSERT ON public.list_views
    FOR EACH ROW EXECUTE FUNCTION public.update_views_count();

CREATE TRIGGER update_list_shares_count
    AFTER INSERT OR DELETE ON public.list_shares
    FOR EACH ROW EXECUTE FUNCTION public.update_shares_count();

-- RLS policies for new tables
ALTER TABLE public.list_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_shares ENABLE ROW LEVEL SECURITY;

-- Views policies
CREATE POLICY "Views are viewable by list owners" ON public.list_views
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.lists
            WHERE lists.id = list_views.list_id
            AND lists.creator_id = auth.uid()
        )
    );

CREATE POLICY "Anyone can create views" ON public.list_views
    FOR INSERT WITH CHECK (true);

-- Shares policies
CREATE POLICY "Shares are viewable by everyone" ON public.list_shares
    FOR SELECT USING (true);

CREATE POLICY "Users can create shares" ON public.list_shares
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own shares" ON public.list_shares
    FOR DELETE USING (auth.uid() = user_id);

-- Mevcut sayıları güncelle
UPDATE public.lists SET 
    likes_count = (SELECT COUNT(*) FROM public.list_likes WHERE list_id = lists.id),
    comments_count = (SELECT COUNT(*) FROM public.list_comments WHERE list_id = lists.id),
    views_count = COALESCE(views_count, 0),
    shares_count = COALESCE(shares_count, 0);

UPDATE public.users_profiles SET
    followers_count = (SELECT COUNT(*) FROM public.user_follows WHERE following_id = users_profiles.id),
    following_count = (SELECT COUNT(*) FROM public.user_follows WHERE follower_id = users_profiles.id),
    lists_count = (SELECT COUNT(*) FROM public.lists WHERE creator_id = users_profiles.id);