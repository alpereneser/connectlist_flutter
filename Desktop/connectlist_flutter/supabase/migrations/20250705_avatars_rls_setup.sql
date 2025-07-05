-- Avatar storage için RLS kurulumu (Doğru yöntem)
-- 2025-07-05: Proper RLS setup for avatars storage

-- 1. Bucket'ı public yap ve RLS'i etkinleştir
UPDATE storage.buckets 
SET 
    public = true,
    file_size_limit = 5242880, -- 5MB
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
WHERE id = 'avatars';

-- 2. Storage objects tablosu için RLS etkinleştir
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Storage objects için policy'leri oluştur
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

-- 4. Bucket durumunu kontrol et
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'avatars';

-- 5. Oluşturulan policy'leri kontrol et
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%avatars%';