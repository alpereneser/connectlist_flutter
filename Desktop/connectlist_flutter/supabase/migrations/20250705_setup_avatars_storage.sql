-- Avatar storage için RLS policy'leri ve ayarlar
-- 2025-07-05: Setup avatars storage bucket policies

-- Avatars bucket için RLS policy'leri oluştur
-- (Bucket Supabase Dashboard'da manuel oluşturulmuş olmalı)

-- 1. Herkes avatar'ları görüntüleyebilir (public read)
INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action)
VALUES (
    'avatars_public_read',
    'avatars',
    'Avatar images are publicly viewable',
    '(true)',
    '(true)',
    'SELECT'
) ON CONFLICT (id) DO NOTHING;

-- 2. Kullanıcılar kendi avatar'larını yükleyebilir
INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action)
VALUES (
    'avatars_authenticated_upload',
    'avatars',
    'Users can upload their own avatars',
    '(auth.uid()::text = (storage.foldername(name))[1])',
    '(auth.uid()::text = (storage.foldername(name))[1])',
    'INSERT'
) ON CONFLICT (id) DO NOTHING;

-- 3. Kullanıcılar kendi avatar'larını güncelleyebilir
INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action)
VALUES (
    'avatars_authenticated_update',
    'avatars',
    'Users can update their own avatars',
    '(auth.uid()::text = (storage.foldername(name))[1])',
    '(auth.uid()::text = (storage.foldername(name))[1])',
    'UPDATE'
) ON CONFLICT (id) DO NOTHING;

-- 4. Kullanıcılar kendi avatar'larını silebilir
INSERT INTO storage.policies (id, bucket_id, name, definition, check_expression, action)
VALUES (
    'avatars_authenticated_delete',
    'avatars',
    'Users can delete their own avatars',
    '(auth.uid()::text = (storage.foldername(name))[1])',
    '(auth.uid()::text = (storage.foldername(name))[1])',
    'DELETE'
) ON CONFLICT (id) DO NOTHING;

-- Alternatif: Eğer yukarıdaki çalışmazsa, basit politikalar
-- Bu durumda aşağıdaki policy'leri kullan:

/*
-- Basit politikalar (Manual olarak Supabase Dashboard'da oluşturulacak)

1. READ Policy:
   Name: "Public read access"
   Definition: true
   
2. INSERT Policy:
   Name: "Authenticated users can upload"
   Definition: auth.role() = 'authenticated'
   
3. UPDATE Policy:
   Name: "Authenticated users can update"
   Definition: auth.role() = 'authenticated'
   
4. DELETE Policy:
   Name: "Authenticated users can delete"
   Definition: auth.role() = 'authenticated'
*/