-- ============================================================
-- PLAYORA BOOKING CANCELLATION & COIN RECOVERY MIGRATION
-- ============================================================

-- 1. Ensure cancellation tracking columns exist on bookings table
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
ADD COLUMN IF NOT EXISTS cancelled_by TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS cancellation_coins_issued NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS owner_compensation NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Ensure wallets & wallet_transactions tables exist
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT UNIQUE NOT NULL,
    balance NUMERIC NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    type TEXT NOT NULL, -- 'credit', 'debit', 'cancellation_credit'
    description TEXT,
    reference_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure reference_id column exists and drop type check constraint if present
ALTER TABLE public.wallet_transactions ADD COLUMN IF NOT EXISTS reference_id TEXT;
ALTER TABLE public.wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;

-- Enable RLS and allow client access for Firebase Auth
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

GRANT ALL ON public.wallets TO anon, authenticated, service_role;
GRANT ALL ON public.wallet_transactions TO anon, authenticated, service_role;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view their own wallet" ON public.wallets;
    DROP POLICY IF EXISTS "Users can view their own wallet transactions" ON public.wallet_transactions;
    DROP POLICY IF EXISTS "Allow public access to wallets" ON public.wallets;
    DROP POLICY IF EXISTS "Allow public access to wallet_transactions" ON public.wallet_transactions;

    CREATE POLICY "Allow public access to wallets" ON public.wallets 
    FOR ALL USING (true) WITH CHECK (true);

    CREATE POLICY "Allow public access to wallet_transactions" ON public.wallet_transactions 
    FOR ALL USING (true) WITH CHECK (true);
END $$;

-- 2b. Ensure cancellation_history table exists
CREATE TABLE IF NOT EXISTS public.cancellation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id TEXT NOT NULL,
    user_id TEXT,
    ground_id UUID,
    ground_name TEXT,
    sport_name TEXT,
    slot_time TIMESTAMP WITH TIME ZONE,
    cancelled_by TEXT NOT NULL, -- 'user', 'owner', 'timeout', 'admin'
    cancellation_reason TEXT,
    refund_percent NUMERIC DEFAULT 0.0,
    coins_issued NUMERIC DEFAULT 0.0,
    owner_compensation NUMERIC DEFAULT 0.0,
    total_booking_amount NUMERIC DEFAULT 0.0,
    cancelled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.cancellation_history ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT ON public.cancellation_history TO anon;
GRANT SELECT, INSERT ON public.cancellation_history TO authenticated;
GRANT ALL ON public.cancellation_history TO service_role;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'cancellation_history' AND policyname = 'Allow public select on cancellation_history'
    ) THEN
        CREATE POLICY "Allow public select on cancellation_history" ON public.cancellation_history 
        FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'cancellation_history' AND policyname = 'Allow insert on cancellation_history'
    ) THEN
        CREATE POLICY "Allow insert on cancellation_history" ON public.cancellation_history 
        FOR INSERT WITH CHECK (true);
    END IF;
END $$;

-- 3. Ensure app_config table exists and seed default cancellation tiers
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO public.app_config (key, value) VALUES
    ('cancellation_tier1_hours', '24'),
    ('cancellation_tier1_percent', '100'),
    ('cancellation_tier2_hours', '12'),
    ('cancellation_tier2_percent', '75'),
    ('cancellation_tier3_hours', '3'),
    ('cancellation_tier3_percent', '50'),
    ('cancellation_tier4_percent', '25'),
    ('coin_expiry_days', '60'),
    ('max_coin_redemption_percent', '40')
ON CONFLICT (key) DO NOTHING;

-- 4. Atomic cancel_booking_by_user function
CREATE OR REPLACE FUNCTION public.cancel_booking_by_user(
    p_booking_id TEXT,
    p_user_id TEXT,
    p_reason TEXT DEFAULT 'Changed my plans'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking RECORD;
    v_ground RECORD;
    v_now TIMESTAMP WITH TIME ZONE := NOW();
    v_hours_remaining NUMERIC;
    v_tier1_h NUMERIC := 24;
    v_tier1_p NUMERIC := 100;
    v_tier2_h NUMERIC := 12;
    v_tier2_p NUMERIC := 75;
    v_tier3_h NUMERIC := 3;
    v_tier3_p NUMERIC := 50;
    v_tier4_p NUMERIC := 25;
    
    v_cfg_val TEXT;
    v_refund_percent NUMERIC := 0;
    v_eligible_amount NUMERIC := 0;
    v_coins_to_issue NUMERIC := 0;
    v_owner_comp NUMERIC := 0;
    v_slot_date_str TEXT;
    v_period_str TEXT;
    v_parts TEXT[];
    v_start_times TEXT[];
    v_start_time TEXT;
    v_slot_price INT;
    v_new_wallet_balance NUMERIC;
    v_owner_id TEXT;
    v_ground_name TEXT := 'the ground';
    v_actual_slot_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- 1. Fetch booking with locking
    SELECT * INTO v_booking 
    FROM public.bookings 
    WHERE id = p_booking_id::uuid 
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Booking not found');
    END IF;

    -- 2. Validate ownership & status
    IF v_booking.user_id <> p_user_id THEN
        RETURN json_build_object('success', false, 'error', 'Unauthorized: You can only cancel your own booking');
    END IF;

    IF LOWER(v_booking.status) IN ('cancelled', 'declined', 'expired') THEN
        RETURN json_build_object('success', false, 'error', 'Booking is already cancelled or expired');
    END IF;

    IF LOWER(v_booking.status) NOT IN ('paid', 'confirmed') THEN
        RETURN json_build_object('success', false, 'error', 'Only confirmed/paid bookings can be cancelled for coins');
    END IF;

    -- Resolve actual slot start time combining date from slot_time and first slot from period (e.g. 'Evening|9:00 PM')
    v_actual_slot_time := v_booking.slot_time;
    v_period_str := v_booking.period;

    IF v_period_str IS NOT NULL AND v_period_str LIKE '%|%' THEN
        v_parts := string_to_array(v_period_str, '|');
        IF array_length(v_parts, 1) >= 2 THEN
            v_start_times := string_to_array(v_parts[2], ',');
            IF array_length(v_start_times, 1) >= 1 THEN
                DECLARE
                    v_raw_t TEXT := trim(v_start_times[1]);
                    v_h INT;
                    v_m INT := 0;
                    v_ampm TEXT := '';
                BEGIN
                    IF v_raw_t LIKE '%-%' THEN
                        v_raw_t := trim(split_part(v_raw_t, '-', 1));
                    END IF;
                    IF v_raw_t LIKE '%:%' THEN
                        v_h := split_part(v_raw_t, ':', 1)::int;
                        IF split_part(v_raw_t, ':', 2) LIKE '% %' THEN
                            v_m := split_part(split_part(v_raw_t, ':', 2), ' ', 1)::int;
                            v_ampm := upper(trim(split_part(split_part(v_raw_t, ':', 2), ' ', 2)));
                        ELSE
                            v_m := split_part(v_raw_t, ':', 2)::int;
                        END IF;
                        IF v_ampm = 'PM' AND v_h <> 12 THEN v_h := v_h + 12; END IF;
                        IF v_ampm = 'AM' AND v_h = 12 THEN v_h := 0; END IF;
                        v_actual_slot_time := (date_trunc('day', v_booking.slot_time AT TIME ZONE 'Asia/Kolkata') + (v_h || ' hours')::interval + (v_m || ' minutes')::interval) AT TIME ZONE 'Asia/Kolkata';
                    END IF;
                EXCEPTION WHEN OTHERS THEN
                    v_actual_slot_time := v_booking.slot_time;
                END;
            END IF;
        END IF;
    END IF;

    IF v_actual_slot_time <= v_now THEN
        RETURN json_build_object('success', false, 'error', 'Cannot cancel a booking after slot start time');
    END IF;

    -- 3. Read dynamic tier thresholds from app_config
    SELECT value INTO v_cfg_val FROM public.app_config WHERE key = 'cancellation_tier1_hours';
    IF v_cfg_val IS NOT NULL AND v_cfg_val <> '' THEN v_tier1_h := v_cfg_val::numeric; END IF;

    SELECT value INTO v_cfg_val FROM public.app_config WHERE key = 'cancellation_tier1_percent';
    IF v_cfg_val IS NOT NULL AND v_cfg_val <> '' THEN v_tier1_p := v_cfg_val::numeric; END IF;

    SELECT value INTO v_cfg_val FROM public.app_config WHERE key = 'cancellation_tier2_hours';
    IF v_cfg_val IS NOT NULL AND v_cfg_val <> '' THEN v_tier2_h := v_cfg_val::numeric; END IF;

    SELECT value INTO v_cfg_val FROM public.app_config WHERE key = 'cancellation_tier2_percent';
    IF v_cfg_val IS NOT NULL AND v_cfg_val <> '' THEN v_tier2_p := v_cfg_val::numeric; END IF;

    SELECT value INTO v_cfg_val FROM public.app_config WHERE key = 'cancellation_tier3_hours';
    IF v_cfg_val IS NOT NULL AND v_cfg_val <> '' THEN v_tier3_h := v_cfg_val::numeric; END IF;

    SELECT value INTO v_cfg_val FROM public.app_config WHERE key = 'cancellation_tier3_percent';
    IF v_cfg_val IS NOT NULL AND v_cfg_val <> '' THEN v_tier3_p := v_cfg_val::numeric; END IF;

    SELECT value INTO v_cfg_val FROM public.app_config WHERE key = 'cancellation_tier4_percent';
    IF v_cfg_val IS NOT NULL AND v_cfg_val <> '' THEN v_tier4_p := v_cfg_val::numeric; END IF;

    -- 4. Calculate hours remaining and eligible refund percentage
    v_hours_remaining := EXTRACT(EPOCH FROM (v_actual_slot_time - v_now)) / 3600.0;

    IF v_hours_remaining >= v_tier1_h THEN
        v_refund_percent := v_tier1_p;
    ELSIF v_hours_remaining >= v_tier2_h THEN
        v_refund_percent := v_tier2_p;
    ELSIF v_hours_remaining >= v_tier3_h THEN
        v_refund_percent := v_tier3_p;
    ELSE
        v_refund_percent := v_tier4_p;
    END IF;

    -- Eligible amount is base slot amount (excluding non-refundable platform fee)
    v_eligible_amount := COALESCE(v_booking.base_amount, v_booking.amount);
    IF v_eligible_amount <= 0 AND v_booking.amount > 0 THEN
        v_eligible_amount := GREATEST(0.0, v_booking.amount - COALESCE(v_booking.platform_fee, 0.0));
    END IF;

    v_coins_to_issue := ROUND(v_eligible_amount * (v_refund_percent / 100.0), 2);
    v_owner_comp := ROUND(v_eligible_amount * ((100.0 - v_refund_percent) / 100.0), 2);

    -- 5. Update booking status
    UPDATE public.bookings SET
        status = 'cancelled',
        cancelled_at = v_now,
        cancellation_reason = p_reason,
        cancelled_by = 'user',
        cancellation_coins_issued = v_coins_to_issue,
        owner_compensation = v_owner_comp,
        owner_earnings = v_owner_comp
    WHERE id = v_booking.id;

    -- 6. Release slot(s) back to available
    v_slot_date_str := to_char(v_booking.slot_time AT TIME ZONE 'UTC', 'YYYY-MM-DD');
    v_period_str := v_booking.period;

    IF v_period_str IS NOT NULL AND v_period_str LIKE '%|%' THEN
        v_parts := string_to_array(v_period_str, '|');
        IF array_length(v_parts, 1) >= 2 THEN
            v_start_times := string_to_array(v_parts[2], ',');
            v_slot_price := CASE 
                WHEN array_length(v_start_times, 1) > 0 
                THEN (v_eligible_amount / array_length(v_start_times, 1))::int 
                ELSE v_eligible_amount::int 
            END;

            FOREACH v_start_time IN ARRAY v_start_times LOOP
                v_start_time := trim(v_start_time);
                IF v_start_time <> '' THEN
                    PERFORM public.upsert_slot(
                        v_booking.ground_id::text,
                        v_slot_date_str,
                        v_start_time,
                        'available',
                        v_slot_price
                    );
                END IF;
            END LOOP;
        END IF;
    END IF;

    -- 7. Credit user's wallet
    IF v_coins_to_issue > 0 THEN
        INSERT INTO public.wallets (user_id, balance, updated_at)
        VALUES (p_user_id, v_coins_to_issue, v_now)
        ON CONFLICT (user_id) DO UPDATE SET
            balance = public.wallets.balance + EXCLUDED.balance,
            updated_at = v_now
        RETURNING balance INTO v_new_wallet_balance;

        -- Record wallet transaction ledger
        INSERT INTO public.wallet_transactions (
            user_id, amount, type, description, reference_id, created_at
        ) VALUES (
            p_user_id,
            v_coins_to_issue,
            'cancellation_credit',
            'Booking cancelled: ' || v_refund_percent::text || '% refund for ' || to_char(v_booking.slot_time, 'DD Mon YYYY'),
            v_booking.id::text,
            v_now
        );
    ELSE
        SELECT balance INTO v_new_wallet_balance FROM public.wallets WHERE user_id = p_user_id;
    END IF;

    -- 7b. Deduct cancelled earnings from owner's wallet
    IF v_booking.owner_earnings IS NOT NULL AND v_booking.owner_earnings > v_owner_comp THEN
        SELECT owner_id INTO v_owner_id FROM public.grounds WHERE id = v_booking.ground_id LIMIT 1;
        IF v_owner_id IS NOT NULL THEN
            UPDATE public.owner_wallets SET
                total_earnings = GREATEST(0.0, total_earnings - (v_booking.owner_earnings - v_owner_comp)),
                available_balance = GREATEST(0.0, available_balance - (v_booking.owner_earnings - v_owner_comp)),
                updated_at = v_now
            WHERE owner_id = v_owner_id;
        END IF;
    END IF;

    -- 8. Fetch ground and owner details for notification
    SELECT g.name, COALESCE(g.owner_id, l.owner_id) as owner_id
    INTO v_ground
    FROM public.grounds g
    LEFT JOIN public.locations l ON g.location_id = l.id
    WHERE g.id = v_booking.ground_id;

    IF v_ground.name IS NOT NULL THEN
        v_ground_name := v_ground.name;
    END IF;
    v_owner_id := v_ground.owner_id;

    -- 9. Insert Notification for Ground Owner (Slot is re-opened)
    IF v_owner_id IS NOT NULL AND v_owner_id <> '' THEN
        INSERT INTO public.notifications (
            user_id, title, message, type, data, is_read, created_at
        ) VALUES (
            v_owner_id,
            'Slot Re-opened (Booking Cancelled)',
            'Booking #' || v_booking.display_id::text || ' for ' || v_ground_name || ' was cancelled by player. The slot is now available.',
            'booking_cancelled',
            json_build_object(
                'booking_id', v_booking.id::text,
                'ground_name', v_ground_name,
                'owner_compensation', v_owner_comp,
                'reason', p_reason
            ),
            false,
            v_now
        );
    END IF;

    -- 10. Insert Notification for Player (Coins credited)
    INSERT INTO public.notifications (
        user_id, title, message, type, data, is_read, created_at
    ) VALUES (
        p_user_id,
        'Booking Cancelled',
        'Your booking for ' || v_ground_name || ' has been cancelled. ' || v_coins_to_issue::text || ' Playora Coins have been added to your wallet.',
        'cancellation_coins_credited',
        json_build_object(
            'booking_id', v_booking.id::text,
            'coins_issued', v_coins_to_issue,
            'refund_percent', v_refund_percent
        ),
        false,
        v_now
    );

    -- 11. Insert into cancellation_history
    INSERT INTO public.cancellation_history (
        booking_id, user_id, ground_id, ground_name, sport_name,
        slot_time, cancelled_by, cancellation_reason, refund_percent,
        coins_issued, owner_compensation, total_booking_amount, cancelled_at
    ) VALUES (
        v_booking.id::text, p_user_id, v_booking.ground_id, v_ground_name, v_booking.sport_name,
        v_booking.slot_time, 'user', p_reason, v_refund_percent,
        v_coins_to_issue, v_owner_comp, v_booking.amount, v_now
    );

    RETURN json_build_object(
        'success', true,
        'booking_id', v_booking.id,
        'status', 'cancelled',
        'refund_percent', v_refund_percent,
        'coins_issued', v_coins_to_issue,
        'owner_compensation', v_owner_comp,
        'wallet_balance', COALESCE(v_new_wallet_balance, 0),
        'hours_remaining', ROUND(v_hours_remaining, 1)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.cancel_booking_by_user(TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.cancel_booking_by_user(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_booking_by_user(TEXT, TEXT, TEXT) TO service_role;

-- 12. Atomic cancel_booking_by_owner function
CREATE OR REPLACE FUNCTION public.cancel_booking_by_owner(
    p_booking_id TEXT,
    p_owner_id TEXT,
    p_reason TEXT DEFAULT 'Cancelled by venue owner',
    p_reopen_slot BOOLEAN DEFAULT TRUE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking RECORD;
    v_ground RECORD;
    v_now TIMESTAMP WITH TIME ZONE := NOW();
    v_refund_amount NUMERIC := 0.0;
    v_slot_date_str TEXT;
    v_period_str TEXT;
    v_parts TEXT[];
    v_start_times TEXT[];
    v_start_time TEXT;
    v_slot_price INT;
    v_new_wallet_balance NUMERIC;
    v_ground_name TEXT := 'the ground';
    v_ground_owner_id TEXT;
BEGIN
    -- 1. Fetch booking with locking
    SELECT * INTO v_booking 
    FROM public.bookings 
    WHERE id = p_booking_id::uuid 
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Booking not found');
    END IF;

    -- 2. Validate status
    IF LOWER(v_booking.status) IN ('cancelled', 'declined', 'expired') THEN
        RETURN json_build_object('success', false, 'error', 'Booking is already cancelled or expired');
    END IF;

    -- 3. Calculate 100% refund amount for player
    v_refund_amount := COALESCE(v_booking.total_amount, v_booking.amount, 0.0);
    IF v_refund_amount <= 0 THEN
        v_refund_amount := COALESCE(v_booking.base_amount, 0.0);
    END IF;

    -- 4. Update booking record
    UPDATE public.bookings SET
        status = 'cancelled',
        cancelled_at = v_now,
        cancellation_reason = p_reason,
        cancelled_by = 'owner',
        cancellation_coins_issued = v_refund_amount,
        owner_compensation = 0.0,
        owner_earnings = 0.0
    WHERE id = v_booking.id;

    -- 5. Release slots if requested
    IF p_reopen_slot THEN
        v_slot_date_str := to_char(v_booking.slot_time AT TIME ZONE 'UTC', 'YYYY-MM-DD');
        v_period_str := v_booking.period;

        IF v_period_str IS NOT NULL AND v_period_str LIKE '%|%' THEN
            v_parts := string_to_array(v_period_str, '|');
            IF array_length(v_parts, 1) >= 2 THEN
                v_start_times := string_to_array(v_parts[2], ',');
                v_slot_price := CASE 
                    WHEN array_length(v_start_times, 1) > 0 
                    THEN (COALESCE(v_booking.base_amount, v_refund_amount) / array_length(v_start_times, 1))::int 
                    ELSE COALESCE(v_booking.base_amount, v_refund_amount)::int 
                END;

                FOREACH v_start_time IN ARRAY v_start_times LOOP
                    v_start_time := trim(v_start_time);
                    IF v_start_time <> '' THEN
                        PERFORM public.upsert_slot(
                            v_booking.ground_id::text,
                            v_slot_date_str,
                            v_start_time,
                            'available',
                            v_slot_price
                        );
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END IF;

    -- 6. Credit 100% refund to user's wallet
    IF v_refund_amount > 0 AND v_booking.user_id IS NOT NULL AND v_booking.user_id <> '' THEN
        INSERT INTO public.wallets (user_id, balance, updated_at)
        VALUES (v_booking.user_id, v_refund_amount, v_now)
        ON CONFLICT (user_id) DO UPDATE SET
            balance = public.wallets.balance + EXCLUDED.balance,
            updated_at = v_now
        RETURNING balance INTO v_new_wallet_balance;

        INSERT INTO public.wallet_transactions (
            user_id, amount, type, description, reference_id, created_at
        ) VALUES (
            v_booking.user_id,
            v_refund_amount,
            'cancellation_credit',
            'Booking cancelled by venue owner: 100% refund for ' || to_char(v_booking.slot_time, 'DD Mon YYYY'),
            v_booking.id::text,
            v_now
        );
    END IF;

    -- 6b. Deduct previous owner_earnings from owner's wallet
    IF v_booking.owner_earnings IS NOT NULL AND v_booking.owner_earnings > 0 THEN
        SELECT owner_id INTO v_ground_owner_id FROM public.grounds WHERE id = v_booking.ground_id LIMIT 1;
        IF v_ground_owner_id IS NOT NULL THEN
            UPDATE public.owner_wallets SET
                total_earnings = GREATEST(0.0, total_earnings - v_booking.owner_earnings),
                available_balance = GREATEST(0.0, available_balance - v_booking.owner_earnings),
                updated_at = v_now
            WHERE owner_id = v_ground_owner_id;
        END IF;
    END IF;

    -- 7. Fetch ground details
    SELECT name INTO v_ground FROM public.grounds WHERE id = v_booking.ground_id;
    IF v_ground.name IS NOT NULL THEN
        v_ground_name := v_ground.name;
    END IF;

    -- 8. Notification to user
    IF v_booking.user_id IS NOT NULL AND v_booking.user_id <> '' THEN
        INSERT INTO public.notifications (
            user_id, title, message, type, data, is_read, created_at
        ) VALUES (
            v_booking.user_id,
            'Booking Cancelled by Venue',
            'Your booking for ' || v_ground_name || ' was cancelled by the venue owner (' || p_reason || '). A 100% refund of ₹' || v_refund_amount::text || ' Playora Coins has been credited to your wallet.',
            'cancellation_coins_credited',
            json_build_object(
                'booking_id', v_booking.id::text,
                'ground_name', v_ground_name,
                'coins_issued', v_refund_amount,
                'refund_percent', 100.0,
                'cancelled_by', 'owner',
                'reason', p_reason
            ),
            false,
            v_now
        );
    END IF;

    -- 9. Insert into cancellation_history
    INSERT INTO public.cancellation_history (
        booking_id, user_id, ground_id, ground_name, sport_name,
        slot_time, cancelled_by, cancellation_reason, refund_percent,
        coins_issued, owner_compensation, total_booking_amount, cancelled_at
    ) VALUES (
        v_booking.id::text, v_booking.user_id, v_booking.ground_id, v_ground_name, v_booking.sport_name,
        v_booking.slot_time, 'owner', p_reason, 100.0,
        v_refund_amount, 0.0, v_refund_amount, v_now
    );

    RETURN json_build_object(
        'success', true,
        'booking_id', v_booking.id,
        'status', 'cancelled',
        'refund_percent', 100.0,
        'coins_issued', v_refund_amount,
        'owner_compensation', 0.0,
        'reason', p_reason
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.cancel_booking_by_owner(TEXT, TEXT, TEXT, BOOLEAN) TO anon;
GRANT EXECUTE ON FUNCTION public.cancel_booking_by_owner(TEXT, TEXT, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_booking_by_owner(TEXT, TEXT, TEXT, BOOLEAN) TO service_role;

-- 13. Allow public read access on app_config
GRANT SELECT ON public.app_config TO anon;
GRANT SELECT ON public.app_config TO authenticated;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'app_config' AND policyname = 'Allow public read access on app_config'
    ) THEN
        CREATE POLICY "Allow public read access on app_config" ON public.app_config 
        FOR SELECT USING (true);
    END IF;
END $$;

-- 14. Keep owner_wallets in sync on payment AND cancellation
CREATE OR REPLACE FUNCTION update_owner_wallet_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_owner_id TEXT;
    v_deduct NUMERIC := 0.0;
BEGIN
    -- 1. Credit wallet when status changes to 'paid' or 'confirmed'
    IF (NEW.status IN ('paid', 'confirmed') AND (OLD.status NOT IN ('paid', 'confirmed') OR OLD.status IS NULL)) THEN
        SELECT owner_id INTO v_owner_id FROM public.grounds WHERE id = NEW.ground_id LIMIT 1;
        
        IF v_owner_id IS NOT NULL AND NEW.owner_earnings > 0 THEN
            INSERT INTO public.owner_wallets (owner_id, total_earnings, available_balance, updated_at)
            VALUES (v_owner_id, NEW.owner_earnings, NEW.owner_earnings, NOW())
            ON CONFLICT (owner_id) DO UPDATE SET
                total_earnings = owner_wallets.total_earnings + NEW.owner_earnings,
                available_balance = owner_wallets.available_balance + NEW.owner_earnings,
                updated_at = NOW();
        END IF;
    END IF;

    -- 2. Deduct from wallet when status changes to 'cancelled'
    IF (NEW.status = 'cancelled' AND (OLD.status IN ('paid', 'confirmed') OR OLD.status IS NULL)) THEN
        SELECT owner_id INTO v_owner_id FROM public.grounds WHERE id = NEW.ground_id LIMIT 1;
        
        IF v_owner_id IS NOT NULL THEN
            v_deduct := GREATEST(0.0, COALESCE(OLD.owner_earnings, NEW.owner_earnings, 0.0) - COALESCE(NEW.owner_compensation, 0.0));
            IF v_deduct > 0 THEN
                UPDATE public.owner_wallets SET
                    total_earnings = GREATEST(0.0, total_earnings - v_deduct),
                    available_balance = GREATEST(0.0, available_balance - v_deduct),
                    updated_at = NOW()
                WHERE owner_id = v_owner_id;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_owner_wallet ON public.bookings;
CREATE TRIGGER trigger_update_owner_wallet
AFTER INSERT OR UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION update_owner_wallet_on_payment();




