const PLUGIN_B64 = "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  const bytes = Uint8Array.from(atob(PLUGIN_B64), c => c.charCodeAt(0));
  return new Response(bytes, {
    headers: {
      ...corsHeaders,
      "Content-Type": "text/plain; charset=utf-8",
      "Content-Disposition": 'attachment; filename="Bloxsmith.lua"',
      "Cache-Control": "no-cache, no-store, must-revalidate",
      "Content-Length": String(bytes.byteLength),
    },
  });
});
