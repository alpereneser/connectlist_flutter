-- Avatar storage için en basit kurulum
-- 2025-07-05: Simple and guaranteed avatars setup

-- 1. Bucket'ı public yap
UPDATE storage.buckets 
SET public = true 
WHERE id = 'avatars';

-- 2. Bucket bilgilerini kontrol et
SELECT 
    id,
    name,
    public,
    created_at
FROM storage.buckets 
WHERE id = 'avatars';

-- 3. Storage şemasındaki tabloları listele (debugging için)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'storage' 
ORDER BY table_name;