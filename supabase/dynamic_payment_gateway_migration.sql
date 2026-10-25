-- Migration: Dynamic Payment Gateway Support (Cashfree & Multi-Gateway)
-- Adds dynamic payment_gateway, cashfree columns, and updates save_booking RPC

-- 1. Ensure columns exist on bookings table
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS payment_gateway TEXT DEFAULT 'cashfree';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cashfree_order_id TEXT;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cashfree_payment_id TEXT;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cashfree_signature TEXT;

-- 2. Drop prior signatures to prevent PGRST203 ambiguity
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text, numeric, numeric, boolean, numeric, numeric);
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text, text, text, text, text, text, text, text);

-- 3. Dynamic save_booking RPC function
CREATE OR REPLACE FUNCTION public.save_booking(
    p_user_id TEXT,
    p_ground_id TEXT,
    p_slot_time TEXT,
    p_amount INT,
    p_status TEXT,
    p_sport_name TEXT DEFAULT NULL,
    p_period TEXT DEFAULT NULL,
    p_payment_gateway TEXT DEFAULT 'cashfree',
    p_order_id TEXT DEFAULT NULL,
    p_payment_id TEXT DEFAULT NULL,
    p_signature TEXT DEFAULT NULL,
    p_cashfree_order_id TEXT DEFAULT NULL,
    p_cashfree_payment_id TEXT DEFAULT NULL,
    p_cashfree_signature TEXT DEFAULT NULL,
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
    v_effective_order_id TEXT;
    v_effective_payment_id TEXT;
    v_effective_signature TEXT;
    v_gateway TEXT;
    result JSON;
BEGIN
    -- Determine effective order/payment identifiers across dynamic & legacy parameter names
    v_effective_order_id := COALESCE(p_order_id, p_cashfree_order_id, p_razorpay_order_id);
    v_effective_payment_id := COALESCE(p_payment_id, p_cashfree_payment_id, p_razorpay_payment_id);
    v_effective_signature := COALESCE(p_signature, p_cashfree_signature, p_razorpay_signature);
    v_gateway := COALESCE(NULLIF(p_payment_gateway, ''), 'cashfree');

    -- Fetch dynamic platform fee & commission rates from app_config
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
        payment_gateway,
        cashfree_order_id, cashfree_payment_id, cashfree_signature,
        razorpay_order_id, razorpay_payment_id, razorpay_signature,
        platform_fee, commission_rate, commission_is_percentage,
        base_amount, owner_earnings, payout_status
    )
    VALUES (
        p_user_id, p_ground_id::uuid, p_slot_time::timestamptz, p_amount, p_status,
        p_sport_name, p_period,
        v_gateway,
        CASE WHEN v_gateway = 'cashfree' THEN v_effective_order_id ELSE NULL END,
        CASE WHEN v_gateway = 'cashfree' THEN v_effective_payment_id ELSE NULL END,
        CASE WHEN v_gateway = 'cashfree' THEN v_effective_signature ELSE NULL END,
        v_effective_order_id, v_effective_payment_id, v_effective_signature,
        v_platform_fee, v_commission_rate, v_commission_is_pct,
        v_base_amount, v_owner_earnings, 'pending'
    )
    RETURNING to_json(bookings.*) INTO result;
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
