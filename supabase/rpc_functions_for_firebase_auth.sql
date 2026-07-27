-- ============================================================
-- SECURITY DEFINER functions for Firebase Auth compatibility
-- ============================================================
-- These functions run with the function owner's privileges,
-- bypassing RLS. The app calls them via supabase.rpc().
-- RLS stays enabled for all direct table access.
--
-- Run this in a NEW query in your Supabase SQL Editor:
-- ============================================================

-- Ensure `grounds` has columns for operating days and slot duration
ALTER TABLE public.grounds
    ADD COLUMN IF NOT EXISTS operating_days TEXT[] DEFAULT ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

ALTER TABLE public.grounds
    ADD COLUMN IF NOT EXISTS slot_duration TEXT DEFAULT '1 Hour';

-- Ensure existing integer slot_duration columns are converted to TEXT so
-- we can store human-friendly strings like '1 Hour' or '30 Minutes'.
ALTER TABLE public.grounds
    ALTER COLUMN slot_duration TYPE TEXT USING slot_duration::text;
ALTER TABLE public.grounds
    ALTER COLUMN slot_duration SET DEFAULT '1 Hour';


-- 1. Favorites: Add
CREATE OR REPLACE FUNCTION public.add_favorite(
    p_user_id TEXT,
    p_ground_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.favorites (user_id, ground_id)
    VALUES (p_user_id, p_ground_id::uuid)
    ON CONFLICT (user_id, ground_id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_favorite(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.add_favorite(TEXT, TEXT) TO authenticated;

-- 2. Favorites: Remove
CREATE OR REPLACE FUNCTION public.remove_favorite(
    p_user_id TEXT,
    p_ground_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.favorites
    WHERE user_id = p_user_id AND ground_id = p_ground_id::uuid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.remove_favorite(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.remove_favorite(TEXT, TEXT) TO authenticated;

-- 3. Bookings: Save
CREATE OR REPLACE FUNCTION public.save_booking(
    p_user_id TEXT,
    p_ground_id TEXT,
    p_slot_time TEXT,
    p_amount INT,
    p_status TEXT,
    p_sport_name TEXT DEFAULT NULL,
    p_period TEXT DEFAULT NULL,
    p_razorpay_order_id TEXT DEFAULT NULL,
    p_razorpay_payment_id TEXT DEFAULT NULL,
    p_razorpay_signature TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    INSERT INTO public.bookings (
        user_id, ground_id, slot_time, amount, status,
        sport_name, period,
        razorpay_order_id, razorpay_payment_id, razorpay_signature
    )
    VALUES (
        p_user_id, p_ground_id::uuid, p_slot_time::timestamptz, p_amount, p_status,
        p_sport_name, p_period,
        p_razorpay_order_id, p_razorpay_payment_id, p_razorpay_signature
    )
    RETURNING to_json(bookings.*) INTO result;
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 4. Slots: Upsert
CREATE OR REPLACE FUNCTION public.upsert_slot(
    p_ground_id TEXT,
    p_date TEXT,
    p_start_time TEXT,
    p_status TEXT,
    p_price INT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.slots (ground_id, date, start_time, status, price)
    VALUES (p_ground_id::uuid, p_date::date, p_start_time::time, p_status, p_price)
    ON CONFLICT (ground_id, date, start_time)
    DO UPDATE SET status = EXCLUDED.status, price = EXCLUDED.price;
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_slot(TEXT, TEXT, TEXT, TEXT, INT) TO anon;
GRANT EXECUTE ON FUNCTION public.upsert_slot(TEXT, TEXT, TEXT, TEXT, INT) TO authenticated;

-- 5. Bookings: Get user bookings (bypasses RLS for Firebase Auth)
CREATE OR REPLACE FUNCTION public.get_user_bookings(p_user_id TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT COALESCE(json_agg(row_to_json(b)), '[]'::json)
        FROM (
            SELECT
                b.id,
                b.user_id,
                b.ground_id,
                b.slot_time,
                b.amount,
                b.status,
                b.sport_name,
                b.period,
                b.razorpay_order_id,
                b.razorpay_payment_id,
                b.razorpay_signature,
                b.checked_in,
                b.checked_in_at,
                b.created_at,
                CASE WHEN g.id IS NOT NULL THEN json_build_object(
                    'id', g.id,
                    'name', g.name,
                    'owner_id', g.owner_id,
                    'location_id', g.location_id,
                    'category', g.category,
                    'opening_time', g.opening_time,
                    'closing_time', g.closing_time,
                    'slot_duration', g.slot_duration,
                    'price_per_hour', g.price_per_hour,
                    'weekend_price', g.weekend_price,
                    'latitude', l.latitude,
                    'longitude', l.longitude,
                    'address', l.address,
                    'city', l.city,
                    'amenities', l.amenities,
                    'owner_id', l.owner_id,
                    'imageUrl', (
                        SELECT image_url FROM public.ground_images
                        WHERE ground_id = g.id LIMIT 1
                    )
                ) ELSE NULL END AS grounds
            FROM public.bookings b
            LEFT JOIN public.grounds g ON b.ground_id = g.id
            LEFT JOIN public.locations l ON g.location_id = l.id
            WHERE b.user_id = p_user_id
            ORDER BY b.slot_time DESC
        ) b
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_bookings(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_user_bookings(TEXT) TO authenticated;

-- 6. Favorites: Get user favorite IDs (bypasses RLS for Firebase Auth)
CREATE OR REPLACE FUNCTION public.get_favorite_ids(p_user_id TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT COALESCE(json_agg(ground_id), '[]'::json)
        FROM public.favorites
        WHERE user_id = p_user_id
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_favorite_ids(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_favorite_ids(TEXT) TO authenticated;

-- 7. Locations: Get all active locations with sports and ratings
CREATE OR REPLACE FUNCTION public.get_locations_with_grounds()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rating numeric;
    v_count int;
BEGIN
    RETURN (
        SELECT COALESCE(json_agg(row_to_json(loc)), '[]'::json)
        FROM (
            SELECT
                l.id,
                l.owner_id,
                l.address,
                l.city,
                l.latitude,
                l.longitude,
                l.amenities,
                l.is_active,
                l.created_at,
                COALESCE(
                    (SELECT array_agg(DISTINCT g.category)
                     FROM public.grounds g
                     WHERE g.location_id = l.id AND g.category IS NOT NULL),
                    '{}'
                ) AS sports,
                COALESCE(
                    (SELECT AVG(r.rating)::numeric(3,2)
                     FROM public.location_reviews r
                     WHERE r.location_id = l.id), 0
                ) AS rating,
                COALESCE(
                    (SELECT COUNT(*)::int
                     FROM public.location_reviews r
                     WHERE r.location_id = l.id), 0
                ) AS total_reviews
            FROM public.locations l
            WHERE l.is_active = true
            ORDER BY l.created_at DESC
        ) loc
    );
EXCEPTION
    WHEN undefined_table THEN
        -- location_reviews table doesn't exist, return locations without ratings
        RETURN (
            SELECT COALESCE(json_agg(row_to_json(loc)), '[]'::json)
            FROM (
                SELECT
                    l.id,
                    l.owner_id,
                    l.address,
                    l.city,
                    l.latitude,
                    l.longitude,
                    l.amenities,
                    l.is_active,
                    l.created_at,
                    COALESCE(
                        (SELECT array_agg(DISTINCT g.category)
                         FROM public.grounds g
                         WHERE g.location_id = l.id AND g.category IS NOT NULL AND g.is_available = true),
                        '{}'
                    ) AS sports,
                    0 AS rating,
                    0 AS total_reviews
                FROM public.locations l
                WHERE l.is_active = true
                ORDER BY l.created_at DESC
            ) loc
        );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_locations_with_grounds() TO anon;
GRANT EXECUTE ON FUNCTION public.get_locations_with_grounds() TO authenticated;

-- ============================================================
-- 8. Grounds: Register new ground (bypasses RLS for Firebase Auth)
-- ============================================================
CREATE OR REPLACE FUNCTION public.register_ground(
    p_owner_id TEXT,
    p_location_id TEXT,
    p_category TEXT,
    p_price_per_hour INT,
    p_weekend_price INT,
    p_opening_time TEXT,
    p_closing_time TEXT,
    p_operating_days TEXT[] DEFAULT ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    p_slot_duration TEXT DEFAULT '1 Hour'
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
    -- Auto-generate name: "Cricket 1", "Volleyball 2", etc.
    SELECT COUNT(*) INTO v_count
    FROM public.grounds
    WHERE owner_id = p_owner_id
      AND location_id = p_location_id::uuid
      AND category = p_category;

    v_display_name := initcap(p_category) || ' ' || (v_count + 1);

    INSERT INTO public.grounds (
        owner_id, location_id, name, category,
        price_per_hour, weekend_price, opening_time, closing_time,
        operating_days, slot_duration
    )
    VALUES (
        p_owner_id, p_location_id::uuid, v_display_name, p_category,
        p_price_per_hour, p_weekend_price, p_opening_time::time, p_closing_time::time,
        p_operating_days, p_slot_duration
    )
    RETURNING to_json(grounds.*) INTO result;
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.register_ground(TEXT, TEXT, TEXT, INT, INT, TEXT, TEXT, TEXT[], TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.register_ground(TEXT, TEXT, TEXT, INT, INT, TEXT, TEXT, TEXT[], TEXT) TO authenticated;

-- ============================================================
-- 9. Ground Images: Insert images (bypasses RLS for Firebase Auth)
-- ============================================================
CREATE OR REPLACE FUNCTION public.insert_ground_images(
    p_ground_id TEXT,
    p_image_urls TEXT[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.ground_images (ground_id, image_url)
    SELECT p_ground_id::uuid, unnest(p_image_urls);
END;
$$;

GRANT EXECUTE ON FUNCTION public.insert_ground_images(TEXT, TEXT[]) TO anon;
GRANT EXECUTE ON FUNCTION public.insert_ground_images(TEXT, TEXT[]) TO authenticated;

-- ============================================================
-- 10. Ground Images: Replace images (bypasses RLS for Firebase Auth)
-- ============================================================
CREATE OR REPLACE FUNCTION public.replace_ground_images(
    p_ground_id TEXT,
    p_image_urls TEXT[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.ground_images WHERE ground_id = p_ground_id::uuid;
    INSERT INTO public.ground_images (ground_id, image_url)
    SELECT p_ground_id::uuid, unnest(p_image_urls);
END;
$$;

GRANT EXECUTE ON FUNCTION public.replace_ground_images(TEXT, TEXT[]) TO anon;
GRANT EXECUTE ON FUNCTION public.replace_ground_images(TEXT, TEXT[]) TO authenticated;

-- ============================================================
-- 11. Grounds: Update ground (bypasses RLS for Firebase Auth)
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_ground(
    p_ground_id TEXT,
    p_category TEXT,
    p_price_per_hour INT,
    p_weekend_price INT,
    p_opening_time TEXT,
    p_closing_time TEXT,
    p_operating_days TEXT[] DEFAULT ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    p_slot_duration TEXT DEFAULT '1 Hour',
    p_is_available BOOLEAN DEFAULT TRUE
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
    -- Get current owner and location
    SELECT owner_id, location_id INTO v_owner_id, v_location_id
    FROM public.grounds WHERE id = p_ground_id::uuid;

    -- Auto-generate name based on new category
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
        opening_time = p_opening_time::time,
        closing_time = p_closing_time::time,
        operating_days = p_operating_days,
        slot_duration = p_slot_duration,
        is_available = p_is_available
    WHERE id = p_ground_id::uuid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_ground(TEXT, TEXT, INT, INT, TEXT, TEXT, TEXT[], TEXT, BOOLEAN) TO anon;
GRANT EXECUTE ON FUNCTION public.update_ground(TEXT, TEXT, INT, INT, TEXT, TEXT, TEXT[], TEXT, BOOLEAN) TO authenticated;

-- ============================================================
-- 12. Slots: Generate slots for a ground (bypasses RLS for Firebase Auth)
-- ============================================================
CREATE OR REPLACE FUNCTION public.generate_ground_slots(
    p_ground_id TEXT,
    p_opening_time TEXT,
    p_closing_time TEXT,
    p_weekday_price INT,
    p_weekend_price INT,
    p_slot_duration TEXT DEFAULT '1 Hour',
    p_operating_days TEXT[] DEFAULT ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET statement_timeout = '120s'
AS $$
DECLARE
    v_open_hour INT;
    v_close_hour INT;
    v_date DATE;
    v_date_str TEXT;
    v_is_weekend BOOLEAN;
    v_slot_price INT;
    v_slot_minutes INT;
    v_curr_time TIME;
    v_end_time TIME;
    v_date_day TEXT;
    v_slot_price_per_slot INT;
    v_slots JSON[];
    v_slot JSON;
    v_allowed_dows INT[] := ARRAY[]::INT[];
    v_in_day TEXT;
BEGIN
    -- parse slot duration (supports formats like '1 Hour', '90 Minutes', '1.5 Hour')
    BEGIN
        v_slot_minutes := NULL;
        IF p_slot_duration IS NULL THEN
            v_slot_minutes := 60;
        ELSE
            -- extract numeric part
            v_slot_minutes := CAST(
                CASE WHEN p_slot_duration ILIKE '%hour%' THEN
                    (CAST(regexp_replace(p_slot_duration, '[^0-9\.]', '', 'g') AS NUMERIC) * 60)
                ELSE
                    CAST(regexp_replace(p_slot_duration, '[^0-9\.]', '', 'g') AS NUMERIC)
                END
            AS INT);
        END IF;
    EXCEPTION WHEN others THEN
        v_slot_minutes := 60;
    END;

    -- validate times
    IF p_opening_time IS NULL OR p_closing_time IS NULL THEN
        RETURN;
    END IF;

    -- normalize operating days into DOW integers (0=Sunday..6=Saturday)
    IF p_operating_days IS NULL THEN
        -- no param provided: default to all days
        v_allowed_dows := ARRAY[0,1,2,3,4,5,6];
    ELSE
        -- if an empty array was provided, treat as no operating days -> nothing to generate
        IF array_length(p_operating_days, 1) = 0 THEN
            RETURN;
        END IF;
        FOR v_in_day IN SELECT unnest(p_operating_days) LOOP
            CASE lower(trim(v_in_day))
                WHEN 'sun' THEN v_allowed_dows := v_allowed_dows || 0;
                WHEN 'sunday' THEN v_allowed_dows := v_allowed_dows || 0;
                WHEN 'mon' THEN v_allowed_dows := v_allowed_dows || 1;
                WHEN 'monday' THEN v_allowed_dows := v_allowed_dows || 1;
                WHEN 'tue' THEN v_allowed_dows := v_allowed_dows || 2;
                WHEN 'tues' THEN v_allowed_dows := v_allowed_dows || 2;
                WHEN 'tuesday' THEN v_allowed_dows := v_allowed_dows || 2;
                WHEN 'wed' THEN v_allowed_dows := v_allowed_dows || 3;
                WHEN 'wednesday' THEN v_allowed_dows := v_allowed_dows || 3;
                WHEN 'thu' THEN v_allowed_dows := v_allowed_dows || 4;
                WHEN 'thur' THEN v_allowed_dows := v_allowed_dows || 4;
                WHEN 'thursday' THEN v_allowed_dows := v_allowed_dows || 4;
                WHEN 'fri' THEN v_allowed_dows := v_allowed_dows || 5;
                WHEN 'friday' THEN v_allowed_dows := v_allowed_dows || 5;
                WHEN 'sat' THEN v_allowed_dows := v_allowed_dows || 6;
                WHEN 'saturday' THEN v_allowed_dows := v_allowed_dows || 6;
                ELSE
                    -- ignore unknown entries
            END CASE;
        END LOOP;
    END IF;

    FOR i IN 0..13 LOOP
        v_date := CURRENT_DATE + i;
        v_date_str := to_char(v_date, 'YYYY-MM-DD');
        -- skip if day not in operating days (use numeric DOW comparison)
        IF array_length(v_allowed_dows,1) IS NOT NULL THEN
            IF NOT (EXTRACT(DOW FROM v_date)::INT = ANY(v_allowed_dows)) THEN
                CONTINUE;
            END IF;
        END IF;

        v_is_weekend := EXTRACT(DOW FROM v_date) IN (0, 6);
        v_slot_price := CASE WHEN v_is_weekend THEN p_weekend_price ELSE p_weekday_price END;

        v_curr_time := p_opening_time::time;
        WHILE (v_curr_time + (v_slot_minutes || ' minutes')::interval) <= p_closing_time::time LOOP
            v_end_time := (v_curr_time + (v_slot_minutes || ' minutes')::interval);
            v_slot_price_per_slot := CAST(ceil((v_slot_price::numeric * v_slot_minutes::numeric) / 60.0) AS INT);

            INSERT INTO public.slots (ground_id, date, start_time, end_time, price, status)
            VALUES (
                p_ground_id::uuid,
                v_date::date,
                v_curr_time,
                v_end_time,
                v_slot_price_per_slot,
                'available'
            )
            ON CONFLICT (ground_id, date, start_time) DO UPDATE
            SET end_time = EXCLUDED.end_time,
                price = EXCLUDED.price,
                status = EXCLUDED.status;

            v_curr_time := v_end_time;
        END LOOP;
    END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_ground_slots(TEXT, TEXT, TEXT, INT, INT, TEXT, TEXT[]) TO anon;
GRANT EXECUTE ON FUNCTION public.generate_ground_slots(TEXT, TEXT, TEXT, INT, INT, TEXT, TEXT[]) TO authenticated;
- -   R u n   t h i s   i n   y o u r   S u p a b a s e   S Q L   E d i t o r  
  
 - -   1 .   C r e a t e   a   d e d i c a t e d   R P C   f o r   t o g g l i n g   a v a i l a b i l i t y   s o   w e   d o n ' t   w i p e   o u t   o t h e r   f i e l d s  
 C R E A T E   O R   R E P L A C E   F U N C T I O N   p u b l i c . t o g g l e _ g r o u n d _ a v a i l a b i l i t y (  
         p _ g r o u n d _ i d   T E X T ,  
         p _ i s _ a v a i l a b l e   B O O L E A N  
 )  
 R E T U R N S   v o i d  
 L A N G U A G E   p l p g s q l  
 S E C U R I T Y   D E F I N E R  
 A S   $ $  
 B E G I N  
         U P D A T E   p u b l i c . g r o u n d s  
         S E T   i s _ a v a i l a b l e   =   p _ i s _ a v a i l a b l e  
         W H E R E   i d   =   p _ g r o u n d _ i d : : u u i d ;  
 E N D ;  
 $ $ ;  
  
 G R A N T   E X E C U T E   O N   F U N C T I O N   p u b l i c . t o g g l e _ g r o u n d _ a v a i l a b i l i t y ( T E X T ,   B O O L E A N )   T O   a n o n ;  
 G R A N T   E X E C U T E   O N   F U N C T I O N   p u b l i c . t o g g l e _ g r o u n d _ a v a i l a b i l i t y ( T E X T ,   B O O L E A N )   T O   a u t h e n t i c a t e d ;  
  
 - -   2 .   U p d a t e   t h e   r e g i s t e r _ g r o u n d   R P C   t o   e n s u r e   i s _ a v a i l a b l e   d e f a u l t s   t o   T R U E  
 C R E A T E   O R   R E P L A C E   F U N C T I O N   p u b l i c . r e g i s t e r _ g r o u n d (  
         p _ o w n e r _ i d   T E X T ,  
         p _ l o c a t i o n _ i d   T E X T ,  
         p _ c a t e g o r y   T E X T ,  
         p _ p r i c e _ p e r _ h o u r   I N T ,  
         p _ w e e k e n d _ p r i c e   I N T ,  
         p _ o p e n i n g _ t i m e   T E X T ,  
         p _ c l o s i n g _ t i m e   T E X T ,  
         p _ o p e r a t i n g _ d a y s   T E X T [ ]   D E F A U L T   A R R A Y [ ' M o n ' , ' T u e ' , ' W e d ' , ' T h u ' , ' F r i ' , ' S a t ' , ' S u n ' ] ,  
         p _ s l o t _ d u r a t i o n   T E X T   D E F A U L T   ' 1   H o u r '  
 )  
 R E T U R N S   J S O N  
 L A N G U A G E   p l p g s q l  
 S E C U R I T Y   D E F I N E R  
 A S   $ $  
 D E C L A R E  
         r e s u l t   J S O N ;  
         v _ c o u n t   I N T ;  
         v _ d i s p l a y _ n a m e   T E X T ;  
 B E G I N  
         - -   A u t o - g e n e r a t e   n a m e :   " C r i c k e t   1 " ,   " V o l l e y b a l l   2 " ,   e t c .  
         S E L E C T   C O U N T ( * )   I N T O   v _ c o u n t  
         F R O M   p u b l i c . g r o u n d s  
         W H E R E   o w n e r _ i d   =   p _ o w n e r _ i d  
             A N D   l o c a t i o n _ i d   =   p _ l o c a t i o n _ i d : : u u i d  
             A N D   c a t e g o r y   =   p _ c a t e g o r y ;  
  
         v _ d i s p l a y _ n a m e   : =   i n i t c a p ( p _ c a t e g o r y )   | |   '   '   | |   ( v _ c o u n t   +   1 ) ;  
  
         I N S E R T   I N T O   p u b l i c . g r o u n d s   (  
                 o w n e r _ i d ,   l o c a t i o n _ i d ,   n a m e ,   c a t e g o r y ,  
                 p r i c e _ p e r _ h o u r ,   w e e k e n d _ p r i c e ,   o p e n i n g _ t i m e ,   c l o s i n g _ t i m e ,  
                 o p e r a t i n g _ d a y s ,   s l o t _ d u r a t i o n ,   i s _ a v a i l a b l e  
         )  
         V A L U E S   (  
                 p _ o w n e r _ i d ,   p _ l o c a t i o n _ i d : : u u i d ,   v _ d i s p l a y _ n a m e ,   p _ c a t e g o r y ,  
                 p _ p r i c e _ p e r _ h o u r ,   p _ w e e k e n d _ p r i c e ,   p _ o p e n i n g _ t i m e : : t i m e ,   p _ c l o s i n g _ t i m e : : t i m e ,  
                 p _ o p e r a t i n g _ d a y s ,   p _ s l o t _ d u r a t i o n ,   T R U E  
         )  
         R E T U R N I N G   t o _ j s o n ( g r o u n d s . * )   I N T O   r e s u l t ;  
         R E T U R N   r e s u l t ;  
 E N D ;  
 $ $ ;  
 