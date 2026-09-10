-- Support Chatbot and Ticketing Tables Migration

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    app_role TEXT NOT NULL DEFAULT 'user', -- 'user' or 'owner'
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    category TEXT NOT NULL DEFAULT 'general',
    subject TEXT,
    status TEXT NOT NULL DEFAULT 'open', -- 'open', 'bot_resolved', 'escalated', 'closed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.support_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL, -- 'user', 'bot', 'agent'
    sender_id TEXT,
    message TEXT NOT NULL,
    payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select on support_tickets" ON public.support_tickets;
CREATE POLICY "Allow select on support_tickets" ON public.support_tickets FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert on support_tickets" ON public.support_tickets;
CREATE POLICY "Allow insert on support_tickets" ON public.support_tickets FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update on support_tickets" ON public.support_tickets;
CREATE POLICY "Allow update on support_tickets" ON public.support_tickets FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow select on support_messages" ON public.support_messages;
CREATE POLICY "Allow select on support_messages" ON public.support_messages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert on support_messages" ON public.support_messages;
CREATE POLICY "Allow insert on support_messages" ON public.support_messages FOR INSERT WITH CHECK (true);
