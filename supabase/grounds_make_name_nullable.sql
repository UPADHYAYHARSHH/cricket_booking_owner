-- Migration: Make name and description nullable in grounds table
-- The register_ground RPC was sending NULL for these columns but the
-- NOT NULL constraint was blocking the insert.

ALTER TABLE public.grounds
  ALTER COLUMN name DROP NOT NULL,
  ALTER COLUMN description DROP NOT NULL;
