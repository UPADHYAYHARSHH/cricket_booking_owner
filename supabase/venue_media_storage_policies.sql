-- venue_media storage policies for Firebase-auth owner app
-- (Supabase client uses anon key; there is no Supabase Auth session.)
-- Run in Supabase SQL Editor if KYC / ground photo uploads fail with RLS errors.

-- Ensure bucket exists and is public (also check Dashboard → Storage)
INSERT INTO storage.buckets (id, name, public)
VALUES ('venue_media', 'venue_media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Allow read for everyone (public URLs)
DROP POLICY IF EXISTS "venue_media_public_read" ON storage.objects;
CREATE POLICY "venue_media_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'venue_media');

-- Allow upload/update/delete via anon key (app authenticates with Firebase)
DROP POLICY IF EXISTS "venue_media_anon_insert" ON storage.objects;
CREATE POLICY "venue_media_anon_insert"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (bucket_id = 'venue_media');

DROP POLICY IF EXISTS "venue_media_anon_update" ON storage.objects;
CREATE POLICY "venue_media_anon_update"
ON storage.objects FOR UPDATE
TO anon, authenticated
USING (bucket_id = 'venue_media')
WITH CHECK (bucket_id = 'venue_media');

DROP POLICY IF EXISTS "venue_media_anon_delete" ON storage.objects;
CREATE POLICY "venue_media_anon_delete"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (bucket_id = 'venue_media');
