-- Trigger: send FCM push notification whenever a row is inserted into notifications
-- Requires: pg_net extension (enabled by default on Supabase)

-- 1. Enable pg_net if not already
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create the trigger function
CREATE OR REPLACE FUNCTION public.send_notification_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  edge_function_url TEXT;
BEGIN
  -- Supabase Edge Function URL — replace <project-ref> with your project ref
  edge_function_url := 'https://qcybnzopffyzmpiaxwbc.supabase.co/functions/v1/send-push-notification';

  -- Fire-and-forget HTTP POST to the Edge Function
  PERFORM net.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg'
    ),
    body := jsonb_build_object('notification_id', NEW.id)
  );

  RETURN NEW;
END;
$$;

-- 3. Create the trigger on the notifications table
DROP TRIGGER IF EXISTS on_notification_created ON public.notifications;
CREATE TRIGGER on_notification_created
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.send_notification_push();
