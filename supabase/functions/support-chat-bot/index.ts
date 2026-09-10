import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") || "";

const SUPPORT_WHATSAPP_NUMBER = "+919876543210";
const SUPPORT_PHONE = "+919876543210";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const {
      ticket_id,
      user_id,
      role = "user",
      message = "",
      category = "general",
      booking_id,
      conversation_history = [],
    } = await req.json();

    if (!user_id || !message) {
      return new Response(JSON.stringify({ error: "user_id and message are required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Fetch contextual booking info if provided or latest
    let bookingContextStr = "No specific booking attached.";
    let activeBooking: any = null;

    if (booking_id) {
      const { data: b } = await supabase
        .from("bookings")
        .select("id, status, amount, slot_time, period, sport_name, grounds(name)")
        .eq("id", booking_id)
        .maybeSingle();
      if (b) {
        activeBooking = b;
        const groundName = (b.grounds as any)?.name ?? "the ground";
        bookingContextStr = `Active Booking: ID ${b.id}, Ground: ${groundName}, Sport: ${b.sport_name ?? 'cricket'}, Status: ${b.status}, Amount: ₹${b.amount}, Slot: ${b.slot_time}, Period: ${b.period}.`;
      }
    } else {
      // Fetch user's latest booking for context
      const { data: recentBookings } = await supabase
        .from("bookings")
        .select("id, status, amount, slot_time, sport_name, grounds(name)")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(1);
      if (recentBookings && recentBookings.length > 0) {
        const b = recentBookings[0];
        activeBooking = b;
        const groundName = (b.grounds as any)?.name ?? "the venue";
        bookingContextStr = `Recent Booking: ID ${b.id}, Ground: ${groundName}, Status: ${b.status}, Amount: ₹${b.amount}, Slot: ${b.slot_time}.`;
      }
    }

    // 2. Build system instructions
    const isOwner = role === "owner";
    const systemPrompt = `You are "TurfPro AI Assistant", an empathetic, fast, and helpful AI support expert for TurfPro / Box Cricket sports venue platform in India.
User Role: ${isOwner ? "Venue / Turf Owner" : "Player / Turf Customer"}.
Current Booking Context: ${bookingContextStr}

PLATFORM RULES & KNOWLEDGE BASE:
1. 45-Minute Booking Approval:
   - When a customer requests a slot, the venue owner has 45 minutes to accept or decline.
   - If the owner approves, the user has 45 minutes to complete payment.
   - If the owner does not respond in 45 minutes, or declines, the request automatically expires and the slot is freed.
2. Instant Booking Mode:
   - Owners can enable "Instant Booking" from their Profile settings. When active, players book and pay immediately without waiting for approval.
3. Payment & Refunds:
   - Payments are processed securely via Razorpay/Cashfree.
   - If an owner declines a request or it expires, refunds are automatic. Usually credited in 3 to 5 business days depending on the player's bank.
   - For split payments: each friend pays their portion. If all do not pay before expiry, paid amounts are refunded.
4. Check-in & Entry:
   - Players show their in-app QR code or Ticket ID (CB-XXXX) to venue staff. Staff marks check-in in the Owner app.
5. Owner Payouts:
   - Turf owner revenue is settled to verified bank accounts every 2-3 business days.
   - Platform fee is minimal and automatically accounted for in financial snapshots.
6. Support Contact:
   - Human support is available via WhatsApp (${SUPPORT_WHATSAPP_NUMBER}) or phone call.

STYLE GUIDELINES:
- Keep answers concise (2 to 4 sentences maximum) and easy to read.
- Use emojis appropriately (🏏, 💰, ⏱️, 📍).
- Always be polite, encouraging, and solutions-oriented.
- If the query is about an escalation (angry user, lost money, turf locked upon arrival), apologize and offer human agent connect.`;

    let reply = "";
    let quickReplies: string[] = [];
    const actions: any[] = [];

    // Check if Gemini API Key is available
    if (GEMINI_API_KEY) {
      try {
        const contents = [
          { role: "user", parts: [{ text: systemPrompt }] },
          ...conversation_history.map((h: any) => ({
            role: h.role === "assistant" || h.role === "bot" ? "model" : "user",
            parts: [{ text: h.text || h.message }],
          })),
          { role: "user", parts: [{ text: message }] },
        ];

        const geminiRes = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ contents }),
          }
        );

        if (geminiRes.ok) {
          const geminiData = await geminiRes.json();
          reply = geminiData.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
        }
      } catch (geminiError) {
        console.error("Gemini API call failed, using intelligent rule engine:", geminiError);
      }
    }

    // Fallback rule engine if Gemini not configured or failed
    if (!reply) {
      const lower = message.toLowerCase();
      if (lower.includes("refund") || lower.includes("money")) {
        reply = isOwner
          ? "Player refunds are handled automatically when a booking is declined or expires. The funds return directly to the player's payment source within 3-5 business days."
          : "Refunds for declined or expired bookings are automatically initiated to your original payment method within 3-5 business days! 💳";
        quickReplies = ["Check Refund Status", "Bank Account Issue", "Talk to Agent"];
      } else if (lower.includes("pending") || lower.includes("approve") || lower.includes("approval") || lower.includes("45")) {
        reply = isOwner
          ? "You have 45 minutes to accept or decline incoming booking requests from your dashboard. If you don't respond, the slot is automatically released to other players. ⏱️"
          : "When you request a slot, the venue owner has 45 minutes to review and approve it. Once approved, you'll receive a notification to pay and secure your slot! ⚡";
        quickReplies = ["How 45m Timer Works", "Instant Booking Option", "View My Bookings"];
      } else if (lower.includes("payout") || lower.includes("bank") || lower.includes("earnings")) {
        reply = isOwner
          ? "Owner payouts are settled directly to your registered bank account every 2-3 business days. You can check your earnings breakdown anytime in the Revenue tab! 📈"
          : "For payment queries, TurfPro supports UPI, Cards, and Net Banking securely via Razorpay/Cashfree.";
        quickReplies = isOwner ? ["View Revenue Report", "Update Bank Details", "Contact Support"] : ["Payment Options", "Split Bill Help"];
      } else if (lower.includes("cancel") || lower.includes("decline")) {
        reply = isOwner
          ? "You can decline any booking request directly from your dashboard or booking details. Slots will be immediately freed up for other bookings."
          : "Bookings can be cancelled before payment. If already paid, cancellation depends on the ground's cancellation policy. Check with the turf owner.";
        quickReplies = ["Cancellation Policy", "Refund Timeline", "Contact Turf"];
      } else if (lower.includes("human") || lower.includes("agent") || lower.includes("call") || lower.includes("whatsapp")) {
        reply = "Our support team is here to assist you! You can connect with our support executive directly via WhatsApp or Phone call. 📞";
        quickReplies = ["WhatsApp Support", "Call Us", "Raise a Ticket"];
        actions.push({
          type: "whatsapp_support",
          label: "Chat on WhatsApp",
          url: `https://wa.me/${SUPPORT_WHATSAPP_NUMBER.replace("+", "")}?text=Hi%20TurfPro%20Support,%20I%20need%20help`,
        });
      } else {
        reply = isOwner
          ? "I'm here to help manage your grounds, booking approvals, payouts, and court settings. What would you like assistance with today? 🏏"
          : "I'm here to help with your turf bookings, slots, payments, and check-in. What can I help you with today? 🏏";
        quickReplies = isOwner
          ? ["Booking Approvals", "Payouts & Settlement", "Slot Management", "WhatsApp Support"]
          : ["Booking Status", "Payment & Refunds", "Check-in Help", "WhatsApp Support"];
      }
    }

    // Default quick replies if empty
    if (quickReplies.length === 0) {
      quickReplies = isOwner
        ? ["45m Approval Timer", "Payout Settlement", "Slot Blocking", "Connect to Human"]
        : ["Refund Timeline", "Check Booking", "Venue Check-in", "Connect to Human"];
    }

    // Contextual Action Card if active booking exists
    if (activeBooking && activeBooking.id) {
      actions.unshift({
        type: "view_booking",
        label: `View Booking #${activeBooking.id.substring(0, 8).toUpperCase()}`,
        booking_id: activeBooking.id,
      });
    }

    // 3. Save message to support_messages if ticket_id is present
    if (ticket_id) {
      try {
        await supabase.from("support_messages").insert([
          {
            ticket_id,
            sender_type: "user",
            sender_id: user_id,
            message: message,
            created_at: new Date().toISOString(),
          },
          {
            ticket_id,
            sender_type: "bot",
            sender_id: "bot",
            message: reply,
            payload: { quick_replies: quickReplies, actions: actions },
            created_at: new Date().toISOString(),
          },
        ]);
      } catch (dbErr) {
        console.error("Failed to persist support messages:", dbErr);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        reply: reply,
        quick_replies: quickReplies,
        actions: actions,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
