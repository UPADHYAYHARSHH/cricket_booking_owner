import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { notification_id } = await req.json();

    if (!notification_id) {
      return new Response(JSON.stringify({ error: "notification_id required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Fetch the notification row
    const { data: notification, error: notifError } = await supabase
      .from("notifications")
      .select("user_id, title, message, type, data")
      .eq("id", notification_id)
      .single();

    if (notifError || !notification) {
      return new Response(JSON.stringify({ error: "Notification not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Fetch FCM tokens for this user
    const { data: tokens, error: tokenError } = await supabase
      .from("fcm_tokens")
      .select("token, platform")
      .eq("user_id", notification.user_id);

    if (tokenError || !tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ error: "No FCM tokens found" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Send push to each token via FCM HTTP v1 API
    const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      return new Response(JSON.stringify({ error: "FCM_SERVICE_ACCOUNT not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const accessToken = await getAccessToken(serviceAccount);

    const type = String(notification.type ?? "");
    let channelId = "user_notifications";
    let soundName: string | undefined = undefined;

    if (type === "booking_request" || type === "new_booking" || type === "booking_confirmed") {
      channelId = "new_booking_channel";
      soundName = "booking_confirmed";
    } else if (type === "booking_approved") {
      channelId = "booking_confirmed_channel";
      soundName = "booking_confirmed";
    } else if (type.includes("owner")) {
      channelId = "owner_notifications";
    }

    // FCM HTTP v1 requires all values in data to be strings
    const stringifiedData: Record<string, string> = {
      title: String(notification.title ?? ""),
      message: String(notification.message ?? ""),
      body: String(notification.message ?? ""),
      type: type,
      notification_id: String(notification_id),
    };

    if (notification.data && typeof notification.data === "object") {
      for (const [k, v] of Object.entries(notification.data)) {
        stringifiedData[k] = typeof v === "object" ? JSON.stringify(v) : String(v ?? "");
      }
    }

    let appTarget = "both";
    if (type.includes("booking_request") || type.includes("new_booking") || type.includes("booking_confirmed") || type.includes("owner")) {
       appTarget = "owner";
    } else if (type.includes("booking_approved") || type.includes("booking_checked_in") || type.includes("booking_cancelled") || type.includes("payment_required")) {
       appTarget = "user";
    }

    let targetTokens = tokens;
    if (appTarget === "owner") {
      targetTokens = tokens.filter((t: any) => !(t.platform || "").startsWith("user"));
    } else if (appTarget === "user") {
      targetTokens = tokens.filter((t: any) => !(t.platform || "").startsWith("owner"));
    }

    let sentCount = 0;
    for (const row of targetTokens) {
      try {
        const messagePayload: any = {
          token: row.token,
          notification: {
            title: notification.title,
            body: notification.message,
          },
          data: stringifiedData,
          android: {
            priority: "high",
            notification: {
              channel_id: channelId,
              ...(soundName ? { sound: soundName } : {}),
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: notification.title,
                  body: notification.message,
                },
                sound: soundName ? `${soundName}.mp3` : "default",
              },
            },
          },
        };

        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify({ message: messagePayload }),
          }
        );

        if (response.ok) {
          sentCount++;
        } else {
          const err = await response.text();
          console.error(`FCM error for token ${row.token}: ${err}`);
        }
      } catch (e) {
        console.error(`Failed to send to ${row.token}: ${e}`);
      }
    }

    return new Response(JSON.stringify({ success: true, sent: sentCount }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

// Generate OAuth2 access token from service account
async function getAccessToken(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: expiry,
  };

  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  // Import the private key
  const pem = serviceAccount.private_key;
  const binaryDer = pemToBinary(pem);

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(signingInput));
  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${signingInput}.${encodedSignature}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}

function pemToBinary(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryString = atob(cleaned);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}
