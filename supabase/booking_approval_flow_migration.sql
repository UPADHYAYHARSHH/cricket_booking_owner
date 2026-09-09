-- ============================================================
-- BOOKING APPROVAL FLOW MIGRATION
-- ============================================================

-- 1. Add require_booking_approval to owner_details
ALTER TABLE public.owner_details 
ADD COLUMN IF NOT EXISTS require_booking_approval BOOLEAN DEFAULT FALSE;

-- 2. Add approved_at to bookings
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;

-- 3. Function to request booking (atomic creation with status 'requested')
CREATE OR REPLACE FUNCTION public.request_booking(
    p_user_id TEXT,
    p_ground_id TEXT,
    p_slot_time TEXT,
    p_amount INT,
    p_sport_name TEXT DEFAULT NULL,
    p_period TEXT DEFAULT NULL,
    p_platform_fee NUMERIC DEFAULT 0.0,
    p_commission_rate NUMERIC DEFAULT 0.0,
    p_commission_is_percentage BOOLEAN DEFAULT true,
    p_base_amount NUMERIC DEFAULT 0.0,
    p_owner_earnings NUMERIC DEFAULT 0.0,
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
BEGIN
    -- Fetch owner and ground name
    SELECT owner_id, name INTO v_owner_id, v_ground_name 
    FROM public.grounds 
    WHERE id = p_ground_id::uuid;

    -- Insert the booking with 'requested' status
    INSERT INTO public.bookings (
        user_id, ground_id, slot_time, amount, status,
        sport_name, period,
        platform_fee, commission_rate, commission_is_percentage, base_amount, owner_earnings,
        created_at
    )
    VALUES (
        p_user_id, p_ground_id::uuid, p_slot_time::timestamptz, p_amount, 'requested',
        p_sport_name, p_period,
        p_platform_fee, p_commission_rate, p_commission_is_percentage, p_base_amount, p_owner_earnings,
        NOW()
    )
    RETURNING id, to_json(bookings.*) INTO new_booking_id, result;

    -- Send notification to owner if found
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


-- 4. Function for owner to approve booking
CREATE OR REPLACE FUNCTION public.approve_booking(
    p_booking_id TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking RECORD;
    v_ground_name TEXT;
BEGIN
    UPDATE public.bookings
    SET status = 'approved',
        approved_at = NOW()
    WHERE id = p_booking_id::uuid AND status = 'requested'
    RETURNING * INTO v_booking;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found or not in requested state';
    END IF;

    -- Fetch ground name
    SELECT name INTO v_ground_name FROM public.grounds WHERE id = v_booking.ground_id;

    -- Send notification to user
    INSERT INTO public.notifications (
        user_id, title, message, type, data, is_read, created_at
    ) VALUES (
        v_booking.user_id,
        'Booking Approved! 🎉 Pay in 45 Mins',
        'Your request for ' || COALESCE(v_ground_name, 'the venue') || ' has been approved! Please complete payment within 45 minutes to lock your slot.',
        'booking_approved',
        json_build_object(
            'booking_id', v_booking.id,
            'ground_id', v_booking.ground_id,
            'amount', v_booking.amount,
            'action', 'payment_required'
        ),
        false,
        NOW()
    );

    RETURN to_json(v_booking);
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_booking(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.approve_booking(TEXT) TO authenticated;


-- 5. Function to delete / expire / decline booking and free slots
CREATE OR REPLACE FUNCTION public.delete_or_expire_booking(
    p_booking_id TEXT,
    p_reason TEXT DEFAULT 'expired' -- 'declined_by_owner', 'expired_owner_timeout', 'expired_user_payment_timeout', 'cancelled_by_user'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking RECORD;
    v_ground_name TEXT;
    v_owner_id TEXT;
    v_user_notif_title TEXT;
    v_user_notif_msg TEXT;
    v_owner_notif_title TEXT;
    v_owner_notif_msg TEXT;
    v_slot_date DATE;
BEGIN
    SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id::uuid;
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', 'Booking not found');
    END IF;

    SELECT name, owner_id INTO v_ground_name, v_owner_id FROM public.grounds WHERE id = v_booking.ground_id;

    -- Prepare notifications according to reason
    IF p_reason = 'declined_by_owner' THEN
        v_user_notif_title := 'Booking Request Declined';
        v_user_notif_msg := 'Your booking request for ' || COALESCE(v_ground_name, 'the ground') || ' was declined by the venue owner.';
    ELSIF p_reason = 'expired_owner_timeout' THEN
        v_user_notif_title := 'Booking Request Expired';
        v_user_notif_msg := 'Your booking request for ' || COALESCE(v_ground_name, 'the ground') || ' expired as the owner did not respond within 45 minutes.';
    ELSIF p_reason = 'expired_user_payment_timeout' THEN
        v_user_notif_title := 'Booking Cancelled (Payment Timeout)';
        v_user_notif_msg := 'Your approved booking for ' || COALESCE(v_ground_name, 'the ground') || ' was cancelled because payment was not completed within 45 minutes.';
        v_owner_notif_title := 'Booking Cancelled (User Timeout)';
        v_owner_notif_msg := 'The approved booking request for ' || COALESCE(v_ground_name, 'the ground') || ' was cancelled because the user did not pay within 45 minutes.';
    ELSE
        v_user_notif_title := 'Booking Cancelled';
        v_user_notif_msg := 'Your booking for ' || COALESCE(v_ground_name, 'the ground') || ' has been cancelled.';
    END IF;

    -- Release slots in slots table if they were marked booked or held
    IF v_booking.period IS NOT NULL AND v_booking.period LIKE '%|%' THEN
        v_slot_date := v_booking.slot_time::date;
        -- Update slots back to available for this ground and date
        UPDATE public.slots 
        SET status = 'available'
        WHERE ground_id = v_booking.ground_id 
          AND date = v_slot_date
          AND status IN ('booked', 'held', 'requested');
    END IF;

    -- Delete the booking
    DELETE FROM public.bookings WHERE id = p_booking_id::uuid;

    -- Insert user notification
    IF v_user_notif_title IS NOT NULL AND v_booking.user_id IS NOT NULL THEN
        INSERT INTO public.notifications (
            user_id, title, message, type, data, is_read, created_at
        ) VALUES (
            v_booking.user_id,
            v_user_notif_title,
            v_user_notif_msg,
            'booking_cancelled',
            json_build_object('ground_name', v_ground_name, 'reason', p_reason),
            false,
            NOW()
        );
    END IF;

    -- Insert owner notification if applicable
    IF v_owner_notif_title IS NOT NULL AND v_owner_id IS NOT NULL THEN
        INSERT INTO public.notifications (
            user_id, title, message, type, data, is_read, created_at
        ) VALUES (
            v_owner_id,
            v_owner_notif_title,
            v_owner_notif_msg,
            'booking_cancelled',
            json_build_object('ground_name', v_ground_name, 'reason', p_reason),
            false,
            NOW()
        );
    END IF;

    RETURN json_build_object('success', true, 'deleted_id', p_booking_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_or_expire_booking(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.delete_or_expire_booking(TEXT, TEXT) TO authenticated;
