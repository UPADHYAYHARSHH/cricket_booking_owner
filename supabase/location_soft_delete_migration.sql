-- Lets an owner soft-delete a location instead of permanently removing it,
-- so booking history is preserved but it stops showing anywhere.
-- Run this manually against your Supabase project's SQL editor.

alter table locations add column if not exists deleted_at timestamptz;
