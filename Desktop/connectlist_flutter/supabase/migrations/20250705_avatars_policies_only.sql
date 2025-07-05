-- Avatar storage için sadece policy'ler (Bucket zaten mevcut)
-- 2025-07-05: Add policies to existing avatars bucket

-- Avatars bucket'ını public yap (eğer değilse)
UPDATE storage.buckets 
SET public = true 
WHERE id = 'avatars';

-- Policy'leri ekle - Farklı tablo yapılarını dene
DO $$
BEGIN
    -- Önce storage.objects_policies tablosunu dene (yeni versiyon)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'storage' AND table_name = 'objects_policies') THEN
        
        -- Public read policy
        INSERT INTO storage.objects_policies (
            id, bucket_id, name, definition, check_expression, "action"
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
            id, bucket_id, name, definition, check_expression, "action"
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
            id, bucket_id, name, definition, check_expression, "action"
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
            id, bucket_id, name, definition, check_expression, "action"
        ) VALUES (
            'avatars-authenticated-delete-policy',
            'avatars',
            'Authenticated users can delete avatars',
            'auth.role() = ''authenticated''',
            'auth.role() = ''authenticated''',
            'DELETE'
        ) ON CONFLICT (id) DO NOTHING;
        
        RAISE NOTICE 'Policies created using objects_policies table';
        
    -- Eğer objects_policies yoksa storage.policies'i dene
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'storage' AND table_name = 'policies') THEN
        
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
        
        RAISE NOTICE 'Policies created using policies table';
        
    ELSE
        RAISE NOTICE 'No suitable policy table found. Manual setup required.';
    END IF;
    
    -- Bucket durumunu kontrol et
    IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'avatars' AND public = true) THEN
        RAISE NOTICE 'Avatars bucket is public and ready';
    ELSE
        RAISE NOTICE 'Avatars bucket needs to be set to public';
    END IF;
END $$;

-- Son kontrol - oluşturulan policy'leri göster
SELECT 
    'Storage Objects Policies' as source,
    name,
    action,
    definition
FROM storage.objects_policies 
WHERE bucket_id = 'avatars'

UNION ALL

SELECT 
    'Storage Policies' as source,
    name,
    action,
    definition
FROM storage.policies 
WHERE bucket_id = 'avatars';