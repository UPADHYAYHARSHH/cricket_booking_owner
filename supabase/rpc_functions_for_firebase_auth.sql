-- ============================================================
-- SECURITY DEFINER functions for Firebase Auth compatibility
-- ============================================================
-- These functions run with the function owner's privileges,
-- bypassing RLS. The app calls them via supabase.rpc().
-- RLS stays enabled for all direct table access.
--
-- Run this in a NEW query in your Supabase SQL Editor:
-- ============================================================

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
                         WHERE g.location_id = l.id AND g.category IS NOT NULL),
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
