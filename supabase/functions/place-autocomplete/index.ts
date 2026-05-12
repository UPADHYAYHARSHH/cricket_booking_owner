// Proxies Google Places Autocomplete (server-side) so browser clients avoid CORS.
// Deploy: supabase functions deploy place-autocomplete
// Secret: supabase secrets set GOOGLE_MAPS_API_KEY=your_key

import { serve } from "https://deno.land/std/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  try {
    const { input } = await req.json()
    const apiKey = Deno.env.get("GOOGLE_MAPS_API_KEY")
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "GOOGLE_MAPS_API_KEY is not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      )
    }

    const params = new URLSearchParams({
      input: String(input ?? ""),
      types: "(cities)",
      components: "country:in",
      key: apiKey,
    })

    const url =
      `https://maps.googleapis.com/maps/api/place/autocomplete/json?${params.toString()}`
    const gRes = await fetch(url)
    const body = await gRes.text()

    return new Response(body, {
      status: gRes.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    )
  }
})
