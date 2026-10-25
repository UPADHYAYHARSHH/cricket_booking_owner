-- Migration: Weekday & Weekend Time-of-Day Pricing (Morning, Afternoon, Evening, Night)
-- Run this in Supabase SQL Editor.

-- 1. Add period price columns to public.grounds table (for both Weekday and Weekend)
ALTER TABLE public.grounds 
  ADD COLUMN IF NOT EXISTS morning_price INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS afternoon_price INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS evening_price INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS night_price INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS weekend_morning_price INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS weekend_afternoon_price INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS weekend_evening_price INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS weekend_night_price INT DEFAULT NULL;

-- 2. Update register_ground RPC with weekday & weekend time-of-day pricing
CREATE OR REPLACE FUNCTION public.register_ground(
    p_owner_id TEXT,
    p_location_id TEXT,
    p_category TEXT,
    p_price_per_hour INT,
    p_weekend_price INT,
    p_opening_time TEXT,
    p_closing_time TEXT,
    p_operating_days TEXT[] DEFAULT ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    p_slot_duration TEXT DEFAULT '1 Hour',
    p_morning_price INT DEFAULT NULL,
    p_afternoon_price INT DEFAULT NULL,
    p_evening_price INT DEFAULT NULL,
    p_night_price INT DEFAULT NULL,
    p_weekend_morning_price INT DEFAULT NULL,
    p_weekend_afternoon_price INT DEFAULT NULL,
    p_weekend_evening_price INT DEFAULT NULL,
    p_weekend_night_price INT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    v_count INT;
    v_display_name TEXT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM public.grounds
    WHERE owner_id = p_owner_id
      AND location_id = p_location_id::uuid
      AND category = p_category;

    v_display_name := initcap(replace(p_category, '_', ' ')) || ' ' || (v_count + 1);

    INSERT INTO public.grounds (
        owner_id, location_id, name, category,
        price_per_hour, weekend_price,
        morning_price, afternoon_price, evening_price, night_price,
        weekend_morning_price, weekend_afternoon_price, weekend_evening_price, weekend_night_price,
        opening_time, closing_time,
        operating_days, slot_duration, is_available
    )
    VALUES (
        p_owner_id, p_location_id::uuid, v_display_name, p_category,
        p_price_per_hour, p_weekend_price,
        p_morning_price, p_afternoon_price, p_evening_price, p_night_price,
        p_weekend_morning_price, p_weekend_afternoon_price, p_weekend_evening_price, p_weekend_night_price,
        p_opening_time::time, p_closing_time::time,
        p_operating_days, p_slot_duration, true
    )
    RETURNING to_json(grounds.*) INTO result;
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.register_ground(TEXT, TEXT, TEXT, INT, INT, TEXT, TEXT, TEXT[], TEXT, INT, INT, INT, INT, INT, INT, INT, INT) TO anon, authenticated;

-- 3. Update update_ground RPC with weekday & weekend time-of-day pricing
CREATE OR REPLACE FUNCTION public.update_ground(
    p_ground_id TEXT,
    p_category TEXT,
    p_price_per_hour INT,
    p_weekend_price INT,
    p_opening_time TEXT,
    p_closing_time TEXT,
    p_operating_days TEXT[] DEFAULT ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    p_slot_duration TEXT DEFAULT '1 Hour',
    p_is_available BOOLEAN DEFAULT TRUE,
    p_morning_price INT DEFAULT NULL,
    p_afternoon_price INT DEFAULT NULL,
    p_evening_price INT DEFAULT NULL,
    p_night_price INT DEFAULT NULL,
    p_weekend_morning_price INT DEFAULT NULL,
    p_weekend_afternoon_price INT DEFAULT NULL,
    p_weekend_evening_price INT DEFAULT NULL,
    p_weekend_night_price INT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_owner_id TEXT;
    v_location_id UUID;
    v_count INT;
    v_display_name TEXT;
BEGIN
    SELECT owner_id, location_id INTO v_owner_id, v_location_id
    FROM public.grounds WHERE id = p_ground_id::uuid;

    SELECT COUNT(*) INTO v_count
    FROM public.grounds
    WHERE owner_id = v_owner_id
      AND location_id = v_location_id
      AND category = p_category
      AND id != p_ground_id::uuid;

    v_display_name := initcap(p_category) || ' ' || (v_count + 1);

    UPDATE public.grounds
    SET name = v_display_name,
        category = p_category,
        price_per_hour = p_price_per_hour,
        weekend_price = p_weekend_price,
        morning_price = p_morning_price,
        afternoon_price = p_afternoon_price,
        evening_price = p_evening_price,
        night_price = p_night_price,
        weekend_morning_price = p_weekend_morning_price,
        weekend_afternoon_price = p_weekend_afternoon_price,
        weekend_evening_price = p_weekend_evening_price,
        weekend_night_price = p_weekend_night_price,
        opening_time = p_opening_time::time,
        closing_time = p_closing_time::time,
        operating_days = p_operating_days,
        slot_duration = p_slot_duration,
        is_available = p_is_available
    WHERE id = p_ground_id::uuid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_ground(TEXT, TEXT, INT, INT, TEXT, TEXT, TEXT[], TEXT, BOOLEAN, INT, INT, INT, INT, INT, INT, INT, INT) TO anon, authenticated;
