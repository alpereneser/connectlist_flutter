-- Avatar storage için basit setup
-- 2025-07-05: Simple avatars storage setup

-- Sadece bucket'ın public olduğundan emin ol
UPDATE storage.buckets 
SET public = true 
WHERE id = 'avatars';

-- Bucket bilgilerini göster
SELECT 
    id,
    name, 
    public,
    created_at
FROM storage.buckets 
WHERE id = 'avatars';

-- Policy'ler manuel olarak Dashboard'da oluşturulacak
-- Şu policy'leri Supabase Dashboard > Storage > avatars > Policies'de oluştur:

/*
1. READ Policy:
   Name: "Public read access"
   Operation: SELECT
   Definition: true

2. INSERT Policy:
   Name: "Authenticated upload"
   Operation: INSERT  
   Definition: auth.role() = 'authenticated'

3. UPDATE Policy:
   Name: "Authenticated update"
   Operation: UPDATE
   Definition: auth.role() = 'authenticated'

4. DELETE Policy:
   Name: "Authenticated delete"
   Operation: DELETE
   Definition: auth.role() = 'authenticated'
*/