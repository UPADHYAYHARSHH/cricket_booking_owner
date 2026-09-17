-- ============================================================
-- FINANCIAL SNAPSHOT & PLATFORM FEE BREAKDOWN FIX
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard)
-- ============================================================

-- 1. Ensure columns exist on bookings table
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS platform_fee NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS commission_rate NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS commission_is_percentage BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS base_amount NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS owner_earnings NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS payout_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS payout_reference TEXT DEFAULT NULL;

-- 2. Drop existing overloaded functions
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text, numeric, numeric, boolean, numeric, numeric);

-- 3. Atomic save_booking function with proper platform fee & owner earnings calculation
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
    v_platform_fee NUMERIC;
    v_commission_rate NUMERIC;
    v_commission_is_pct BOOLEAN;
    v_base_amount NUMERIC;
    v_owner_earnings NUMERIC;
    v_db_fee TEXT;
    v_db_comm TEXT;
    v_db_is_pct TEXT;
    v_db_fee_free TEXT;
    v_is_fee_free BOOLEAN;
    result JSON;
BEGIN
    -- Fetch dynamic configuration from app_config table
    SELECT value INTO v_db_fee FROM public.app_config WHERE key = 'platform_fee' LIMIT 1;
    SELECT value INTO v_db_comm FROM public.app_config WHERE key = 'commission_rate' LIMIT 1;
    SELECT value INTO v_db_is_pct FROM public.app_config WHERE key = 'commission_is_percentage' LIMIT 1;
    SELECT value INTO v_db_fee_free FROM public.app_config WHERE key IN ('platform_fee_is_free', 'is_platform_fee_free', 'convenience_fee_is_free') LIMIT 1;

    v_platform_fee := COALESCE(NULLIF(v_db_fee, '')::numeric, 0.0);
    v_commission_rate := COALESCE(NULLIF(v_db_comm, '')::numeric, 0.0);
    v_commission_is_pct := COALESCE((v_db_is_pct IS NULL OR v_db_is_pct = 'true' OR v_db_is_pct = '1'), true);
    v_is_fee_free := COALESCE((v_db_fee_free = 'true' OR v_db_fee_free = '1'), false);

    IF v_is_fee_free THEN
        v_base_amount := p_amount;
    ELSE
        v_base_amount := GREATEST(0.0, p_amount - v_platform_fee);
    END IF;

    IF v_commission_is_pct THEN
        v_owner_earnings := GREATEST(0.0, v_base_amount - (v_base_amount * (v_commission_rate / 100.0)));
    ELSE
        v_owner_earnings := GREATEST(0.0, v_base_amount - v_commission_rate);
    END IF;

    INSERT INTO public.bookings (
        user_id, ground_id, slot_time, amount, status,
        sport_name, period,
        razorpay_order_id, razorpay_payment_id, razorpay_signature,
        platform_fee, commission_rate, commission_is_percentage,
        base_amount, owner_earnings, payout_status
    )
    VALUES (
        p_user_id, p_ground_id::uuid, p_slot_time::timestamptz, p_amount, p_status,
        p_sport_name, p_period,
        p_razorpay_order_id, p_razorpay_payment_id, p_razorpay_signature,
        v_platform_fee, v_commission_rate, v_commission_is_pct,
        v_base_amount, v_owner_earnings, 'pending'
    )
    RETURNING to_json(bookings.*) INTO result;
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;


-- 4. Update request_booking function to compute or accept accurate financial snapshot
CREATE OR REPLACE FUNCTION public.request_booking(
    p_user_id TEXT,
    p_ground_id TEXT,
    p_slot_time TEXT,
    p_amount INT,
    p_sport_name TEXT DEFAULT NULL,
    p_period TEXT DEFAULT NULL,
    p_platform_fee NUMERIC DEFAULT NULL,
    p_commission_rate NUMERIC DEFAULT NULL,
    p_commission_is_percentage BOOLEAN DEFAULT NULL,
    p_base_amount NUMERIC DEFAULT NULL,
    p_owner_earnings NUMERIC DEFAULT NULL,
    p_player_name TEXT DEFAULT NULL,
    p_player_phone TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    new_booking_id UUID;
    v_owner_id TEXT;
    v_ground_name TEXT;
    v_platform_fee NUMERIC := p_platform_fee;
    v_commission_rate NUMERIC := p_commission_rate;
    v_commission_is_pct BOOLEAN := p_commission_is_percentage;
    v_base_amount NUMERIC := p_base_amount;
    v_owner_earnings NUMERIC := p_owner_earnings;
    v_db_fee TEXT;
    v_db_comm TEXT;
    v_db_is_pct TEXT;
    v_db_fee_free TEXT;
    v_is_fee_free BOOLEAN;
BEGIN
    IF v_platform_fee IS NULL OR v_base_amount IS NULL OR v_owner_earnings IS NULL THEN
        SELECT value INTO v_db_fee FROM public.app_config WHERE key = 'platform_fee' LIMIT 1;
        SELECT value INTO v_db_comm FROM public.app_config WHERE key = 'commission_rate' LIMIT 1;
        SELECT value INTO v_db_is_pct FROM public.app_config WHERE key = 'commission_is_percentage' LIMIT 1;
        SELECT value INTO v_db_fee_free FROM public.app_config WHERE key IN ('platform_fee_is_free', 'is_platform_fee_free', 'convenience_fee_is_free') LIMIT 1;

        v_platform_fee := COALESCE(v_platform_fee, NULLIF(v_db_fee, '')::numeric, 0.0);
        v_commission_rate := COALESCE(v_commission_rate, NULLIF(v_db_comm, '')::numeric, 0.0);
        v_commission_is_pct := COALESCE(v_commission_is_pct, (v_db_is_pct IS NULL OR v_db_is_pct = 'true' OR v_db_is_pct = '1'), true);
        v_is_fee_free := COALESCE((v_db_fee_free = 'true' OR v_db_fee_free = '1'), false);

        IF v_base_amount IS NULL THEN
            IF v_is_fee_free THEN
                v_base_amount := p_amount;
            ELSE
                v_base_amount := GREATEST(0.0, p_amount - v_platform_fee);
            END IF;
        END IF;

        IF v_owner_earnings IS NULL THEN
            IF v_commission_is_pct THEN
                v_owner_earnings := GREATEST(0.0, v_base_amount - (v_base_amount * (v_commission_rate / 100.0)));
            ELSE
                v_owner_earnings := GREATEST(0.0, v_base_amount - v_commission_rate);
            END IF;
        END IF;
    END IF;

    SELECT owner_id, name INTO v_owner_id, v_ground_name 
    FROM public.grounds 
    WHERE id = p_ground_id::uuid;

    INSERT INTO public.bookings (
        user_id, ground_id, slot_time, amount, status,
        sport_name, period,
        platform_fee, commission_rate, commission_is_percentage, base_amount, owner_earnings,
        payout_status,
        created_at
    )
    VALUES (
        p_user_id, p_ground_id::uuid, p_slot_time::timestamptz, p_amount, 'requested',
        p_sport_name, p_period,
        v_platform_fee, v_commission_rate, v_commission_is_pct, v_base_amount, v_owner_earnings,
        'pending',
        NOW()
    )
    RETURNING id, to_json(bookings.*) INTO new_booking_id, result;

    IF v_owner_id IS NOT NULL THEN
        INSERT INTO public.notifications (
            user_id, title, message, type, data, is_read, created_at
        ) VALUES (
            v_owner_id,
            'New Booking Request! ⚡',
            COALESCE(p_player_name, 'A player') || ' requested a slot at ' || COALESCE(v_ground_name, 'your venue') || '. You have 45 minutes to confirm.',
            'booking_request',
            json_build_object(
                'booking_id', new_booking_id,
                'ground_id', p_ground_id,
                'ground_name', v_ground_name,
                'amount', p_amount,
                'slot_time', p_slot_time,
                'action', 'owner_approval_required'
            ),
            false,
            NOW()
        );
    END IF;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.request_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, NUMERIC, NUMERIC, BOOLEAN, NUMERIC, NUMERIC, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.request_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, NUMERIC, NUMERIC, BOOLEAN, NUMERIC, NUMERIC, TEXT, TEXT) TO authenticated;
