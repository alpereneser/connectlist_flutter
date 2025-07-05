-- Profil için eksik alanları ekleyen migration
-- 2025-07-05: Add profile fields (website, location, etc.)

-- users_profiles tablosuna yeni alanlar ekle
ALTER TABLE public.users_profiles 
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS location TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS phone_number TEXT,
ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}';

-- Notification settings tablosu oluştur
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

-- Privacy settings tablosu oluştur
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

-- Account deletion requests tablosu
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

-- Support tickets tablosu
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

-- İndeksler oluştur
CREATE INDEX IF NOT EXISTS idx_user_notification_settings_user_id ON public.user_notification_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_privacy_settings_user_id ON public.user_privacy_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_user_id ON public.account_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_status ON public.account_deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);

-- RLS policies
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_privacy_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Notification settings policies
CREATE POLICY "Users can view own notification settings" ON public.user_notification_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notification settings" ON public.user_notification_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification settings" ON public.user_notification_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Privacy settings policies
CREATE POLICY "Users can view own privacy settings" ON public.user_privacy_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own privacy settings" ON public.user_privacy_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own privacy settings" ON public.user_privacy_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Account deletion policies
CREATE POLICY "Users can view own deletion requests" ON public.account_deletion_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create deletion requests" ON public.account_deletion_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own deletion requests" ON public.account_deletion_requests
    FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Support tickets policies
CREATE POLICY "Users can view own support tickets" ON public.support_tickets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create support tickets" ON public.support_tickets
    FOR INSERT WITH CHECK (true); -- Anyone can create tickets

CREATE POLICY "Users can update own support tickets" ON public.support_tickets
    FOR UPDATE USING (auth.uid() = user_id);

-- Updated_at trigger fonksiyonu (eğer yoksa)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Updated_at trigger'ları
CREATE TRIGGER update_user_notification_settings_updated_at
    BEFORE UPDATE ON public.user_notification_settings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_privacy_settings_updated_at
    BEFORE UPDATE ON public.user_privacy_settings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_account_deletion_requests_updated_at
    BEFORE UPDATE ON public.account_deletion_requests
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at
    BEFORE UPDATE ON public.support_tickets
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

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
CREATE OR REPLACE TRIGGER create_user_settings_on_signup
    AFTER INSERT ON public.users_profiles
    FOR EACH ROW EXECUTE FUNCTION public.create_user_default_settings();