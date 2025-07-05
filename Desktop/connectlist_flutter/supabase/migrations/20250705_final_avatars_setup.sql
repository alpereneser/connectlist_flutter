-- Avatar storage için son deneme - RLS policy yaklaşımı
-- 2025-07-05: Final attempt with RLS policies on storage.objects

-- 1. Avatars bucket'ını public yap
UPDATE storage.buckets 
SET public = true 
WHERE id = 'avatars';

-- 2. storage.objects tablosunda RLS'i etkinleştir
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Eski policy'leri temizle (eğer varsa)
DROP POLICY IF EXISTS "Public read access for avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete avatars" ON storage.objects;

-- 4. Yeni RLS policy'leri oluştur
-- Public read policy
CREATE POLICY "Public read access for avatars" ON storage.objects
FOR SELECT
USING (bucket_id = 'avatars');

-- Authenticated insert policy
CREATE POLICY "Authenticated users can upload avatars" ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
);

-- Authenticated update policy
CREATE POLICY "Authenticated users can update avatars" ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
)
WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
);

-- Authenticated delete policy
CREATE POLICY "Authenticated users can delete avatars" ON storage.objects
FOR DELETE
USING (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
);

-- 5. Kontrol sorguları
SELECT 
    'Bucket Status' as type,
    id as name,
    public::text as status,
    created_at::text as info
FROM storage.buckets 
WHERE id = 'avatars'

UNION ALL

SELECT 
    'RLS Policy' as type,
    policyname as name,
    cmd as status,
    qual as info
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%avatars%';