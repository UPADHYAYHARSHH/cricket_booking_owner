-- Splits the venue/sport bundle on `grounds` into a `locations` table (one
-- venue, many grounds) and single-sport `grounds` rows.
-- Run this manually against your Supabase project's SQL editor.

create table if not exists locations (
  id uuid primary key default gen_random_uuid(),
  owner_id text not null,
  address text not null,
  city text not null default '',
  google_maps_link text,
  latitude double precision not null default 0,
  longitude double precision not null default 0,
  created_at timestamptz not null default now()
);

-- In case `locations` already existed before `amenities` was added to this
-- migration (CREATE TABLE IF NOT EXISTS is a no-op on an existing table, so
-- this needs to be a separate, explicit ALTER).
alter table locations add column if not exists amenities text[] not null default '{}';

alter table grounds
  add column if not exists location_id uuid references locations(id),
  add column if not exists category text;

alter table grounds
  drop column if exists address,
  drop column if exists city,
  drop column if exists latitude,
  drop column if exists longitude,
  drop column if exists google_maps_link,
  drop column if exists categories,
  drop column if exists sports_config,
  drop column if exists amenities;

-- Enable/disable toggles for locations and grounds, and booking check-in.
alter table locations add column if not exists is_active boolean not null default true;
alter table grounds add column if not exists is_available boolean not null default true;
alter table bookings add column if not exists checked_in boolean not null default false;
alter table bookings add column if not exists checked_in_at timestamptz;

-- Per-location property/ownership documents (separate from the owner-level
-- KYC documents collected once during onboarding).
alter table locations add column if not exists property_status text;
alter table locations add column if not exists property_document_url text;
alter table locations add column if not exists noc_url text;
alter table locations add column if not exists documents_verified boolean not null default false;

-- IMPORTANT: copy whatever RLS policies `grounds` has today (owner can
-- select/insert/update/delete own rows via owner_id) onto `locations` too.
-- These aren't tracked in the repo, so they must be set up manually in the
-- Supabase dashboard / SQL editor.
