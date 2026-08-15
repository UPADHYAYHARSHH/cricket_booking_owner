-- This script fixes the RLS (Row Level Security) error when uploading location images from the Owner App.
-- Since the owner app uses Firebase Auth, Supabase sees all requests as 'anon'.
-- We need to add RLS policies to allow inserts, updates, and deletes for the anon role on the location_images table.

-- First, make sure RLS is enabled
ALTER TABLE public.location_images ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to avoid conflicts
DROP POLICY IF EXISTS "Allow public read of location images" ON public.location_images;
DROP POLICY IF EXISTS "Allow anon insert to location images" ON public.location_images;
DROP POLICY IF EXISTS "Allow anon update to location images" ON public.location_images;
DROP POLICY IF EXISTS "Allow anon delete to location images" ON public.location_images;

-- 1. Allow everyone to read the images
CREATE POLICY "Allow public read of location images"
ON public.location_images FOR SELECT
USING (true);

-- 2. Allow anon (Firebase authenticated users) to insert images
CREATE POLICY "Allow anon insert to location images"
ON public.location_images FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- 3. Allow anon to update images (if needed)
CREATE POLICY "Allow anon update to location images"
ON public.location_images FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- 4. Allow anon to delete images (the app deletes existing images before inserting new ones)
CREATE POLICY "Allow anon delete to location images"
ON public.location_images FOR DELETE
TO anon, authenticated
USING (true);
