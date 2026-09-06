-- Migration: Add payout tracking columns to bookings table

-- 1. Add payout columns
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS payout_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS payout_reference TEXT DEFAULT NULL;

-- 2. Drop existing save_booking function to recreate it with the new column
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text);

-- 3. Recreate save_booking function matching the latest schema + payout_status
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
    result JSON;
BEGIN
    -- Fetch dynamic configuration from app_config table
    SELECT value INTO v_db_fee FROM public.app_config WHERE key = 'platform_fee' LIMIT 1;
    SELECT value INTO v_db_comm FROM public.app_config WHERE key = 'commission_rate' LIMIT 1;
    SELECT value INTO v_db_is_pct FROM public.app_config WHERE key = 'commission_is_percentage' LIMIT 1;

    v_platform_fee := COALESCE(NULLIF(v_db_fee, '')::numeric, 30.0);
    v_commission_rate := COALESCE(NULLIF(v_db_comm, '')::numeric, 0.0);
    v_commission_is_pct := COALESCE((v_db_is_pct IS NULL OR v_db_is_pct = 'true' OR v_db_is_pct = '1'), true);

    v_base_amount := GREATEST(0.0, p_amount - v_platform_fee);

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
