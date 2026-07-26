-- ============================================================
-- Fix: Allow owner bookings (user_id NULL) + add notes column
-- ============================================================
-- Owner bookings intentionally set user_id = NULL to distinguish
-- them from customer bookings. The original schema had user_id NOT NULL
-- and an RLS policy requiring auth.uid() = user_id, which blocked
-- the owner app (Firebase Auth — no Supabase auth session).

-- 1. Make user_id nullable so owner bookings (user_id = NULL) are allowed
ALTER TABLE public.bookings ALTER COLUMN user_id DROP NOT NULL;

-- 2. Add notes column if it doesn't exist (owner can leave an optional note)
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS notes TEXT;

-- 3. SECURITY DEFINER function to insert owner bookings (bypasses RLS)
CREATE OR REPLACE FUNCTION public.save_owner_booking(
    p_ground_id TEXT,
    p_slot_time TEXT,
    p_amount INT,
    p_sport_name TEXT DEFAULT NULL,
    p_period TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
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
        sport_name, period, notes, checked_in
    )
    VALUES (
        NULL, p_ground_id::uuid, p_slot_time::timestamptz, p_amount, 'confirmed',
        p_sport_name, p_period, p_notes, false
    )
    RETURNING to_json(bookings.*) INTO result;
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_owner_booking(TEXT, TEXT, INT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.save_owner_booking(TEXT, TEXT, INT, TEXT, TEXT, TEXT) TO authenticated;

-- 4. SECURITY DEFINER function to delete owner bookings (bypasses RLS)
CREATE OR REPLACE FUNCTION public.delete_owner_booking(
    p_booking_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.bookings WHERE id = p_booking_id::uuid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_owner_booking(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.delete_owner_booking(TEXT) TO authenticated;
