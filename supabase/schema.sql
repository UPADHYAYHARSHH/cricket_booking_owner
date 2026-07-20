-- Create bookings table
-- NOTE: ground_id is UUID in the actual database (not TEXT).
-- user_id is TEXT because firebase_uid_migration converted it for Firebase Auth.
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    ground_id UUID NOT NULL,
    slot_time TIMESTAMP WITH TIME ZONE NOT NULL,
    amount INTEGER NOT NULL, -- in paise/INR subunits
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'paid', 'failed', 'confirmed'
    sport_name TEXT,
    period TEXT,
    razorpay_order_id TEXT,
    razorpay_payment_id TEXT,
    razorpay_signature TEXT,
    checked_in BOOLEAN NOT NULL DEFAULT false,
    checked_in_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Allow users to see their own bookings
CREATE POLICY "Users can view their own bookings" 
ON public.bookings FOR SELECT 
USING (auth.uid() = user_id);

-- Allow users to create their own bookings (initially pending)
CREATE POLICY "Users can create their own bookings" 
ON public.bookings FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Optional: Allow Edge Functions (service_role) to update status
-- (Service role bypasses RLS by default, so no extra policy needed for standard Edge Functions)
