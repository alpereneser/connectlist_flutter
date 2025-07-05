-- Eksik alanları ve tabloları ekleyen optimize edilmiş migration
-- 2025-07-05: Add missing fields and tables for settings functionality

-- users_profiles tablosuna eksik alanları ekle (sadece yoksa)
DO $$ 
BEGIN
    -- Website alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'website') THEN
        ALTER TABLE public.users_profiles ADD COLUMN website TEXT;
    END IF;

    -- Location alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'location') THEN
        ALTER TABLE public.users_profiles ADD COLUMN location TEXT;
    END IF;

    -- Phone number alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'phone_number') THEN
        ALTER TABLE public.users_profiles ADD COLUMN phone_number TEXT;
    END IF;

    -- Date of birth alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'date_of_birth') THEN
        ALTER TABLE public.users_profiles ADD COLUMN date_of_birth DATE;
    END IF;

    -- Gender alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'gender') THEN
        ALTER TABLE public.users_profiles ADD COLUMN gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say'));
    END IF;

    -- Is private alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'is_private') THEN
        ALTER TABLE public.users_profiles ADD COLUMN is_private BOOLEAN DEFAULT false;
    END IF;

    -- Is verified alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'is_verified') THEN
        ALTER TABLE public.users_profiles ADD COLUMN is_verified BOOLEAN DEFAULT false;
    END IF;

    -- Social links alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'social_links') THEN
        ALTER TABLE public.users_profiles ADD COLUMN social_links JSONB DEFAULT '{}';
    END IF;

    -- Preferences alanı kontrolü ve eklenmesi
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users_profiles' AND column_name = 'preferences') THEN
        ALTER TABLE public.users_profiles ADD COLUMN preferences JSONB DEFAULT '{}';
    END IF;
END $$;

-- Notification settings tablosu oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    sms_notifications BOOLEAN DEFAULT false,
    list_likes BOOLEAN DEFAULT true,
    list_comments BOOLEAN DEFAULT true,
    new_followers BOOLEAN DEFAULT true,
    list_shares BOOLEAN DEFAULT true,
    weekly_digest BOOLEAN DEFAULT true,
    product_updates BOOLEAN DEFAULT false,
    tips_and_tutorials BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Privacy settings tablosu oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.user_privacy_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    profile_visibility TEXT DEFAULT 'public' CHECK (profile_visibility IN ('public', 'private', 'friends_only')),
    show_email BOOLEAN DEFAULT false,
    show_phone BOOLEAN DEFAULT false,
    show_location BOOLEAN DEFAULT true,
    show_birth_date BOOLEAN DEFAULT false,
    allow_search_by_email BOOLEAN DEFAULT true,
    allow_search_by_phone BOOLEAN DEFAULT false,
    show_online_status BOOLEAN DEFAULT true,
    allow_friend_requests BOOLEAN DEFAULT true,
    allow_list_comments BOOLEAN DEFAULT true,
    allow_list_likes BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Account deletion requests tablosu oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    reason TEXT,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    scheduled_deletion_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'cancelled', 'completed')),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Support tickets tablosu oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users_profiles(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    category TEXT DEFAULT 'general' CHECK (category IN ('general', 'bug_report', 'feature_request', 'account_issue', 'privacy_concern', 'other')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'waiting_response', 'resolved', 'closed')),
    admin_response TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- İndeksler oluştur (eğer yoksa)
CREATE INDEX IF NOT EXISTS idx_user_notification_settings_user_id ON public.user_notification_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_privacy_settings_user_id ON public.user_privacy_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_user_id ON public.account_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_status ON public.account_deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);

-- RLS policies sadece yeni tablolar için
DO $$
BEGIN
    -- user_notification_settings için RLS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_notification_settings') THEN
        ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
        
        -- Policies oluştur (eğer yoksa)
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_notification_settings' AND policyname = 'Users can view own notification settings') THEN
            CREATE POLICY "Users can view own notification settings" ON public.user_notification_settings
                FOR SELECT USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_notification_settings' AND policyname = 'Users can update own notification settings') THEN
            CREATE POLICY "Users can update own notification settings" ON public.user_notification_settings
                FOR UPDATE USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_notification_settings' AND policyname = 'Users can insert own notification settings') THEN
            CREATE POLICY "Users can insert own notification settings" ON public.user_notification_settings
                FOR INSERT WITH CHECK (auth.uid() = user_id);
        END IF;
    END IF;

    -- user_privacy_settings için RLS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_privacy_settings') THEN
        ALTER TABLE public.user_privacy_settings ENABLE ROW LEVEL SECURITY;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_privacy_settings' AND policyname = 'Users can view own privacy settings') THEN
            CREATE POLICY "Users can view own privacy settings" ON public.user_privacy_settings
                FOR SELECT USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_privacy_settings' AND policyname = 'Users can update own privacy settings') THEN
            CREATE POLICY "Users can update own privacy settings" ON public.user_privacy_settings
                FOR UPDATE USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_privacy_settings' AND policyname = 'Users can insert own privacy settings') THEN
            CREATE POLICY "Users can insert own privacy settings" ON public.user_privacy_settings
                FOR INSERT WITH CHECK (auth.uid() = user_id);
        END IF;
    END IF;

    -- account_deletion_requests için RLS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'account_deletion_requests') THEN
        ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'account_deletion_requests' AND policyname = 'Users can view own deletion requests') THEN
            CREATE POLICY "Users can view own deletion requests" ON public.account_deletion_requests
                FOR SELECT USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'account_deletion_requests' AND policyname = 'Users can create deletion requests') THEN
            CREATE POLICY "Users can create deletion requests" ON public.account_deletion_requests
                FOR INSERT WITH CHECK (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'account_deletion_requests' AND policyname = 'Users can update own deletion requests') THEN
            CREATE POLICY "Users can update own deletion requests" ON public.account_deletion_requests
                FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');
        END IF;
    END IF;

    -- support_tickets için RLS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'support_tickets') THEN
        ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'support_tickets' AND policyname = 'Users can view own support tickets') THEN
            CREATE POLICY "Users can view own support tickets" ON public.support_tickets
                FOR SELECT USING (auth.uid() = user_id);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'support_tickets' AND policyname = 'Users can create support tickets') THEN
            CREATE POLICY "Users can create support tickets" ON public.support_tickets
                FOR INSERT WITH CHECK (true);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'support_tickets' AND policyname = 'Users can update own support tickets') THEN
            CREATE POLICY "Users can update own support tickets" ON public.support_tickets
                FOR UPDATE USING (auth.uid() = user_id);
        END IF;
    END IF;
END $$;

-- Updated_at trigger fonksiyonu (eğer yoksa)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Updated_at trigger'ları (eğer yoksa)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_notification_settings_updated_at') THEN
        CREATE TRIGGER update_user_notification_settings_updated_at
            BEFORE UPDATE ON public.user_notification_settings
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_privacy_settings_updated_at') THEN
        CREATE TRIGGER update_user_privacy_settings_updated_at
            BEFORE UPDATE ON public.user_privacy_settings
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_account_deletion_requests_updated_at') THEN
        CREATE TRIGGER update_account_deletion_requests_updated_at
            BEFORE UPDATE ON public.account_deletion_requests
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_support_tickets_updated_at') THEN
        CREATE TRIGGER update_support_tickets_updated_at
            BEFORE UPDATE ON public.support_tickets
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;

-- Yeni kullanıcılar için default settings oluşturan fonksiyon
CREATE OR REPLACE FUNCTION public.create_user_default_settings()
RETURNS trigger AS $$
BEGIN
    -- Default notification settings
    INSERT INTO public.user_notification_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Default privacy settings
    INSERT INTO public.user_privacy_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Yeni kullanıcı oluşturulduğunda default settings oluşturan trigger
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'create_user_settings_on_signup') THEN
        CREATE TRIGGER create_user_settings_on_signup
            AFTER INSERT ON public.users_profiles
            FOR EACH ROW EXECUTE FUNCTION public.create_user_default_settings();
    END IF;
END $$;

-- Mevcut kullanıcılar için default settings oluştur
INSERT INTO public.user_notification_settings (user_id)
SELECT id FROM public.users_profiles
WHERE id NOT IN (SELECT user_id FROM public.user_notification_settings);

INSERT INTO public.user_privacy_settings (user_id)
SELECT id FROM public.users_profiles
WHERE id NOT IN (SELECT user_id FROM public.user_privacy_settings);