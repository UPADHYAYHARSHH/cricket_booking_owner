CREATE OR REPLACE FUNCTION delete_user_and_data(user_uuid UUID)
RETURNS void AS $$
BEGIN
  -- 1. Manually delete all child records from tables that reference the user
  -- We use dynamic SQL (EXECUTE format(...)) and check if the table exists first.
  -- This prevents errors if a table (like 'loyalty_points') hasn't been created yet.
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'favorites') THEN
    EXECUTE format('DELETE FROM public.favorites WHERE user_id = %L', user_uuid);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reviews') THEN
    EXECUTE format('DELETE FROM public.reviews WHERE user_id = %L', user_uuid);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'loyalty_points') THEN
    EXECUTE format('DELETE FROM public.loyalty_points WHERE user_id = %L', user_uuid);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bookings') THEN
    EXECUTE format('DELETE FROM public.bookings WHERE user_id = %L', user_uuid);
  END IF;
  
  -- If you also have a public "users" or "profiles" table:
  -- IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
  --   EXECUTE format('DELETE FROM public.users WHERE id = %L', user_uuid);
  -- END IF;

  -- 2. Finally, delete the user from the Supabase Authentication schema
  DELETE FROM auth.users WHERE id = user_uuid;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
