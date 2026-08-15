-- Run this in your Supabase SQL Editor to add the privacy_policy column
ALTER TABLE locations ADD COLUMN IF NOT EXISTS privacy_policy TEXT;
