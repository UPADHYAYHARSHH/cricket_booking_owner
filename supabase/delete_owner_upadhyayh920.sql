-- ============================================================
-- SQL Script to Delete All Data for Owner: upadhyayh920@gmail.com
-- Owner ID: 6s0WMT4WeRgG6qZqLjg0g0Cn0lk1
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

DO $$
DECLARE
    v_owner_id TEXT := '6s0WMT4WeRgG6qZqLjg0g0Cn0lk1';
    v_email TEXT := 'upadhyayh920@gmail.com';
    v_ground_ids UUID[];
    v_location_ids UUID[];
BEGIN
    -- 1. Identify all grounds and locations owned by this user
    SELECT COALESCE(array_agg(id), ARRAY[]::UUID[]) INTO v_ground_ids 
    FROM public.grounds 
    WHERE owner_id = v_owner_id;

    SELECT COALESCE(array_agg(id), ARRAY[]::UUID[]) INTO v_location_ids 
    FROM public.locations 
    WHERE owner_id = v_owner_id;

    -- Also add any grounds referencing these locations
    SELECT COALESCE(array_agg(id), ARRAY[]::UUID[]) INTO v_ground_ids
    FROM public.grounds
    WHERE owner_id = v_owner_id OR location_id = ANY(v_location_ids);

    -- 2. Delete cancellation history records
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'cancellation_history') THEN
        DELETE FROM public.cancellation_history 
        WHERE user_id = v_owner_id 
           OR ground_id = ANY(v_ground_ids);
    END IF;

    -- 3. Delete bookings
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bookings') THEN
        DELETE FROM public.bookings 
        WHERE user_id = v_owner_id 
           OR ground_id = ANY(v_ground_ids);
    END IF;

    -- 4. Delete slots
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'slots') THEN
        DELETE FROM public.slots 
        WHERE ground_id = ANY(v_ground_ids);
    END IF;

    -- 5. Delete location reviews & images
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'location_reviews') THEN
        DELETE FROM public.location_reviews 
        WHERE user_id = v_owner_id 
           OR location_id = ANY(v_location_ids);
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'location_images') THEN
        DELETE FROM public.location_images 
        WHERE location_id = ANY(v_location_ids);
    END IF;

    -- 6. Delete grounds
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'grounds') THEN
        DELETE FROM public.grounds 
        WHERE owner_id = v_owner_id 
           OR location_id = ANY(v_location_ids);
    END IF;

    -- 7. Delete locations
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'locations') THEN
        DELETE FROM public.locations 
        WHERE owner_id = v_owner_id;
    END IF;

    -- 8. Delete withdrawals & owner wallets
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'withdrawals') THEN
        DELETE FROM public.withdrawals 
        WHERE owner_id = v_owner_id;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'owner_wallets') THEN
        DELETE FROM public.owner_wallets 
        WHERE owner_id = v_owner_id;
    END IF;

    -- 9. Delete user wallet & transactions
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'wallet_transactions') THEN
        DELETE FROM public.wallet_transactions 
        WHERE user_id = v_owner_id;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'wallets') THEN
        DELETE FROM public.wallets 
        WHERE user_id = v_owner_id;
    END IF;

    -- 10. Delete notifications & fcm tokens
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN
        DELETE FROM public.notifications 
        WHERE user_id = v_owner_id;
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'fcm_tokens') THEN
        DELETE FROM public.fcm_tokens 
        WHERE user_id = v_owner_id;
    END IF;

    -- 11. Delete owner details
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'owner_details') THEN
        DELETE FROM public.owner_details 
        WHERE id = v_owner_id 
           OR business_email = v_email;
    END IF;

    RAISE NOTICE 'Finished: All records for owner % (%) have been deleted.', v_owner_id, v_email;
END $$;
