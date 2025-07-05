-- Avatar storage için RLS policy'leri (Düzeltilmiş versiyon)
-- 2025-07-05: Setup avatars storage bucket policies - FIXED

-- Storage bucket'ının var olup olmadığını kontrol et
DO $$
BEGIN
    -- Bucket'ın var olup olmadığını kontrol et
    IF NOT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'avatars'
    ) THEN
        -- Bucket yoksa oluştur
        INSERT INTO storage.buckets (id, name, public)
        VALUES ('avatars', 'avatars', true);
        
        RAISE NOTICE 'Avatar bucket oluşturuldu';
    ELSE
        RAISE NOTICE 'Avatar bucket zaten mevcut';
        
        -- Bucket'ı public yap (eğer değilse)
        UPDATE storage.buckets 
        SET public = true 
        WHERE id = 'avatars' AND public = false;
    END IF;
END $$;

-- RLS Policy'lerini Storage API ile oluşturmak için doğru yaklaşım
-- Bu policy'ler Supabase Dashboard'da manuel olarak oluşturulmalı veya
-- Supabase CLI ile oluşturulmalı.

-- Alternatif: SQL fonksiyonları ile policy oluşturma
DO $$
DECLARE
    bucket_name text := 'avatars';
BEGIN
    -- Mevcut policy'leri temizle (eğer varsa)
    PERFORM storage.delete_policy_if_exists(bucket_name, 'avatars_public_read');
    PERFORM storage.delete_policy_if_exists(bucket_name, 'avatars_authenticated_upload');
    PERFORM storage.delete_policy_if_exists(bucket_name, 'avatars_authenticated_update');
    PERFORM storage.delete_policy_if_exists(bucket_name, 'avatars_authenticated_delete');
    
    -- Yeni policy'leri oluştur
    -- 1. Public read access
    PERFORM storage.create_policy(
        bucket_name,
        'avatars_public_read',
        'SELECT',
        'true'::text,
        'true'::text
    );
    
    -- 2. Authenticated users can upload
    PERFORM storage.create_policy(
        bucket_name,
        'avatars_authenticated_upload', 
        'INSERT',
        'auth.role() = ''authenticated''',
        'auth.role() = ''authenticated'''
    );
    
    -- 3. Authenticated users can update
    PERFORM storage.create_policy(
        bucket_name,
        'avatars_authenticated_update',
        'UPDATE', 
        'auth.role() = ''authenticated''',
        'auth.role() = ''authenticated'''
    );
    
    -- 4. Authenticated users can delete
    PERFORM storage.create_policy(
        bucket_name,
        'avatars_authenticated_delete',
        'DELETE',
        'auth.role() = ''authenticated''',
        'auth.role() = ''authenticated'''
    );
    
    RAISE NOTICE 'Storage policy''leri başarıyla oluşturuldu';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Policy oluşturma hatası: %. Manuel oluşturma gerekli.', SQLERRM;
END $$;