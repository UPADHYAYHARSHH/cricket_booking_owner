-- Create split_requests table
CREATE TABLE IF NOT EXISTS public.split_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_amount DECIMAL NOT NULL,
    upi_id TEXT,
    qr_code_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'settled'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create split_members table
CREATE TABLE IF NOT EXISTS public.split_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    split_request_id UUID REFERENCES public.split_requests(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    amount DECIMAL NOT NULL,
    is_received BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.split_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_members ENABLE ROW LEVEL SECURITY;

-- Policies for split_requests
CREATE POLICY "Users can manage their own split requests" 
ON public.split_requests FOR ALL 
USING (auth.uid() = user_id);

-- Policies for split_members
-- Bookers can manage members of their own split requests
CREATE POLICY "Users can manage members of their own split requests" 
ON public.split_members FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.split_requests 
        WHERE id = public.split_members.split_request_id 
        AND user_id = auth.uid()
    )
);

-- Storage Bucket Setup (This usually needs to be done via dashboard or API)
-- To be run in Supabase Storage SQL:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('qr_codes', 'qr_codes', true);
-- CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'qr_codes');
-- CREATE POLICY "Authenticated Upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'qr_codes' AND auth.role() = 'authenticated');
