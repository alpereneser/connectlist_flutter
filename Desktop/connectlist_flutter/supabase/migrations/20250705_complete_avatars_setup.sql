-- Avatar storage için komple kurulum - Tek dosya
-- 2025-07-05: Complete avatars storage setup with bucket and policies

-- 1. Avatars bucket'ını oluştur (eğer yoksa)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars', 
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

-- 2. Bucket RLS'i etkinleştir
UPDATE storage.buckets 
SET public = true 
WHERE id = 'avatars';

-- 3. Avatars bucket için policy'leri oluştur
-- Policy tablosuna doğrudan insert

-- Public read policy
INSERT INTO storage.objects_policies (
    id,
    bucket_id,
    name,
    definition,
    check_expression,
    "action"
) VALUES (
    'avatars-public-read-policy',
    'avatars',
    'Public read access for avatars',
    'true',
    'true', 
    'SELECT'
) ON CONFLICT (id) DO NOTHING;

-- Authenticated insert policy  
INSERT INTO storage.objects_policies (
    id,
    bucket_id, 
    name,
    definition,
    check_expression,
    "action"
) VALUES (
    'avatars-authenticated-insert-policy',
    'avatars',
    'Authenticated users can upload avatars',
    'auth.role() = ''authenticated''',
    'auth.role() = ''authenticated''',
    'INSERT'
) ON CONFLICT (id) DO NOTHING;

-- Authenticated update policy
INSERT INTO storage.objects_policies (
    id,
    bucket_id,
    name, 
    definition,
    check_expression,
    "action"
) VALUES (
    'avatars-authenticated-update-policy',
    'avatars',
    'Authenticated users can update avatars',
    'auth.role() = ''authenticated''',
    'auth.role() = ''authenticated''',
    'UPDATE'
) ON CONFLICT (id) DO NOTHING;

-- Authenticated delete policy
INSERT INTO storage.objects_policies (
    id,
    bucket_id,
    name,
    definition, 
    check_expression,
    "action"
) VALUES (
    'avatars-authenticated-delete-policy',
    'avatars',
    'Authenticated users can delete avatars',
    'auth.role() = ''authenticated''',
    'auth.role() = ''authenticated''',
    'DELETE'
) ON CONFLICT (id) DO NOTHING;

-- 4. Alternatif policy yapısı (eğer yukarısı çalışmazsa)
DO $$
BEGIN
    -- storage.policies tablosu varsa bu yöntemi kullan
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'storage' AND table_name = 'policies') THEN
        
        -- Public read
        INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action)
        VALUES (
            'avatars-public-read', 
            'avatars',
            'Public read access',
            'true',
            'true',
            'SELECT'
        ) ON CONFLICT (id) DO NOTHING;
        
        -- Authenticated insert
        INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action) 
        VALUES (
            'avatars-authenticated-insert',
            'avatars', 
            'Authenticated upload',
            'auth.role() = ''authenticated''',
            'auth.role() = ''authenticated''',
            'INSERT'
        ) ON CONFLICT (id) DO NOTHING;
        
        -- Authenticated update
        INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action)
        VALUES (
            'avatars-authenticated-update',
            'avatars',
            'Authenticated update', 
            'auth.role() = ''authenticated''',
            'auth.role() = ''authenticated''',
            'UPDATE'
        ) ON CONFLICT (id) DO NOTHING;
        
        -- Authenticated delete
        INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action)
        VALUES (
            'avatars-authenticated-delete',
            'avatars',
            'Authenticated delete',
            'auth.role() = ''authenticated''',
            'auth.role() = ''authenticated''',
            'DELETE'
        ) ON CONFLICT (id) DO NOTHING;
        
        RAISE NOTICE 'Storage policies created successfully using storage.policies table';
    ELSE
        RAISE NOTICE 'storage.policies table not found, using objects_policies instead';
    END IF;
END $$;

-- 5. Bucket durumunu kontrol et
DO $$
DECLARE
    bucket_exists boolean;
    bucket_public boolean;
BEGIN
    SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'avatars') INTO bucket_exists;
    
    IF bucket_exists THEN
        SELECT public FROM storage.buckets WHERE id = 'avatars' INTO bucket_public;
        RAISE NOTICE 'Avatars bucket exists and is public: %', bucket_public;
    ELSE
        RAISE NOTICE 'Avatars bucket does not exist!';
    END IF;
END $$;

-- 6. Oluşturulan policy'leri listele
SELECT 
    'Bucket Info' as type,
    id as name,
    public::text as status,
    created_at::text as created
FROM storage.buckets 
WHERE id = 'avatars'

UNION ALL

SELECT 
    'Policy' as type,
    name,
    action as status,
    created_at::text as created
FROM storage.objects_policies 
WHERE bucket_id = 'avatars'

UNION ALL

SELECT 
    'Policy (Alt)' as type,
    name,
    action as status, 
    created_at::text as created
FROM storage.policies 
WHERE bucket_id = 'avatars';

RAISE NOTICE 'Avatars storage setup completed successfully!';