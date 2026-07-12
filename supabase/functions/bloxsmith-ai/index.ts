// Bloxsmith AI backend — secure proxy between the Roblox Studio plugin and AI providers.
// The plugin never holds an AI key; it only knows this function's public URL.
import { corsHeaders } from "npm:@supabase/supabase-js@2/cors";

const LOVABLE_GATEWAY = "https://ai.gateway.lovable.dev/v1/chat/completions";
const DEFAULT_MODEL = "google/gemini-3-flash-preview";

type ChatMessage = { role: "system" | "user" | "assistant"; content: string };

interface RequestBody {
  mode?: string;
  messages?: ChatMessage[];
  prompt?: string;
  context?: unknown;
}

const BASE_SYSTEM = `You are Bloxsmith, an elite AI copilot embedded inside Roblox Studio.
You help creators build, debug, optimize and manage Roblox games. You are precise, safe and production-focused.

RULES:
- Target Roblox Luau. Use modern, idiomatic, well-commented, performant Luau.
- Prefer RemoteEvents/RemoteFunctions correctly split between Server (ServerScriptService) and Client (StarterPlayerScripts/StarterGui).
- Never write exploitable server logic: validate all client input on the server, never trust the client for currency/inventory/damage.
- Use task.wait / task.spawn (never wait()/spawn()), use :GetService, avoid deprecated APIs.
- When you output code, wrap each file in a fenced block that starts with the language and a path hint, e.g.:
  \`\`\`lua path=ServerScriptService/ShopService name=ShopService class=Script
  -- code
  \`\`\`
  class is one of: Script, LocalScript, ModuleScript.
- Keep explanations concise and skimmable with short headers and bullet points.`;

const MODE_SYSTEM: Record<string, string> = {
  chat: "Answer the user's Roblox development question. Include code only when helpful.",
  generate_script:
    "Generate complete, ready-to-use Luau script(s) for the request. Always include a path= and class= hint on every code block so the plugin can insert it in the right place.",
  fix_script:
    "Analyze the provided script, find bugs, security issues and deprecated APIs, then return a corrected full version in a single code block plus a short bulleted change log.",
  explain_script:
    "Explain the provided script clearly: what it does, key functions, data flow, and any risks. No need to rewrite it unless asked.",
  optimize_script:
    "Optimize the provided script for performance and readability. Return the improved full script in one code block and a bulleted list of the optimizations made.",
  generate_ui:
    "Generate a Roblox UI. Produce a LocalScript (class=LocalScript) that builds the interface programmatically under a ScreenGui, using UICorner, UIListLayout/UIGridLayout, and theme-consistent colors. Make it responsive with Scale-based UDim2 where sensible.",
  generate_system:
    "Generate a complete, modular game system (e.g. inventory, shop, quests, combat, leaderboard, progression). Split into server ModuleScript(s), RemoteEvents, and client controller(s). Each file in its own code block with path= and class= hints. Include a short setup guide.",
  security_scan:
    "You are a Roblox security auditor. Review the provided project context/scripts. Return findings as a markdown list grouped by severity (Critical/High/Medium/Low). For each: title, why it's exploitable, and the fix. End with a one-line overall risk summary.",
  performance:
    "You are a Roblox performance analyst. Review the context/scripts for lag sources: unthrottled loops, per-frame allocations, excessive parts, RunService.Heartbeat misuse, memory leaks (connections never disconnected), and network spam. Return prioritized findings with concrete fixes.",
  cleanup:
    "Suggest project cleanup: naming conventions, folder organization, duplicate detection, and dead code. Return an actionable checklist.",
  docs:
    "Generate clear Markdown documentation for the provided script(s)/system: overview, API/functions, parameters, return values, events, and usage examples.",
  recommend:
    "Act as a Roblox game consultant. Based on the project context, give prioritized recommendations across four areas: Gameplay, Monetization, Retention, and UX. Keep each item concrete and specific to what you see.",
  agent:
    `You are operating as a multi-step build agent. Produce the code needed to complete the task.
After your explanation, emit ONE actions block the plugin can apply, formatted exactly as:
\`\`\`bloxsmith:actions
[{"action":"create_script","path":"ServerScriptService","name":"ShopService","class":"Script","source":"-- luau here"}]
\`\`\`
Valid actions: create_script, replace_script (requires "target" full path), create_folder (name+path). Always include the human-readable code blocks too.`,
};

function buildSystem(mode: string, context: unknown): string {
  const parts = [BASE_SYSTEM];
  if (MODE_SYSTEM[mode]) parts.push(`TASK MODE (${mode}): ${MODE_SYSTEM[mode]}`);
  if (context && (typeof context !== "object" || Object.keys(context as object).length)) {
    parts.push(
      "PROJECT CONTEXT (from the user's live Roblox Studio session — use it to be specific):\n" +
        (typeof context === "string" ? context : JSON.stringify(context)).slice(0, 12000),
    );
  }
  return parts.join("\n\n");
}

async function callLovable(messages: ChatMessage[]): Promise<string> {
  const key = Deno.env.get("LOVABLE_API_KEY");
  if (!key) throw new Response("Missing LOVABLE_API_KEY", { status: 500 });
  const res = await fetch(LOVABLE_GATEWAY, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({ model: Deno.env.get("BLOXSMITH_MODEL") || DEFAULT_MODEL, messages, temperature: 0.4 }),
  });
  if (res.status === 429) throw { status: 429, msg: "Rate limit reached. Please wait a moment and try again." };
  if (res.status === 402) throw { status: 402, msg: "AI credits exhausted. Add credits to keep generating." };
  if (!res.ok) throw { status: 502, msg: `AI provider error (${res.status}): ${(await res.text()).slice(0, 300)}` };
  const data = await res.json();
  return data?.choices?.[0]?.message?.content ?? "";
}

// NVIDIA NIM (OpenAI-compatible) — primary provider. Serves GLM and other hosted models.
async function callNvidia(messages: ChatMessage[]): Promise<string> {
  const key = Deno.env.get("NVIDIA_API_KEY");
  const model = Deno.env.get("NVIDIA_MODEL") || "z-ai/glm-5.2";
  if (!key) throw { status: 500, msg: "NVIDIA_API_KEY not set" };
  const res = await fetch("https://integrate.api.nvidia.com/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({ model, messages, temperature: 0.4, max_tokens: 4096 }),
  });
  if (res.status === 429) throw { status: 429, msg: "Rate limit reached. Please wait a moment and try again." };
  if (res.status === 401 || res.status === 403)
    throw { status: 502, msg: `NVIDIA authentication failed (${res.status}). Check the API key.` };
  if (!res.ok) throw { status: 502, msg: `NVIDIA error (${res.status}): ${(await res.text()).slice(0, 300)}` };
  const data = await res.json();
  return data?.choices?.[0]?.message?.content ?? "";
}

// Provider abstraction — Bedrock path is ready for when a valid key is supplied.
async function callBedrock(messages: ChatMessage[]): Promise<string> {
  const key = Deno.env.get("BEDROCK_API_KEY");
  const region = Deno.env.get("BEDROCK_REGION") || "us-east-1";
  const model = Deno.env.get("BEDROCK_MODEL") || "us.anthropic.claude-3-5-sonnet-20240620-v1:0";
  if (!key) throw { status: 500, msg: "BEDROCK_API_KEY not set" };
  const system = messages.filter((m) => m.role === "system").map((m) => ({ text: m.content }));
  const convo = messages.filter((m) => m.role !== "system").map((m) => ({ role: m.role, content: [{ text: m.content }] }));
  const res = await fetch(
    `https://bedrock-runtime.${region}.amazonaws.com/model/${encodeURIComponent(model)}/converse`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
      body: JSON.stringify({ system, messages: convo, inferenceConfig: { maxTokens: 4096, temperature: 0.4 } }),
    },
  );
  if (!res.ok) throw { status: 502, msg: `Bedrock error (${res.status}): ${(await res.text()).slice(0, 300)}` };
  const data = await res.json();
  return data?.output?.message?.content?.map((c: { text?: string }) => c.text ?? "").join("") ?? "";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body = (await req.json()) as RequestBody;
    const mode = typeof body.mode === "string" ? body.mode : "chat";
    const history = Array.isArray(body.messages) ? body.messages : [];
    const prompt = typeof body.prompt === "string" ? body.prompt : "";

    const convo: ChatMessage[] = history.filter(
      (m) => m && (m.role === "user" || m.role === "assistant") && typeof m.content === "string",
    );
    if (prompt) convo.push({ role: "user", content: prompt });
    if (convo.length === 0) {
      return new Response(JSON.stringify({ error: "No prompt or messages provided" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const messages: ChatMessage[] = [{ role: "system", content: buildSystem(mode, body.context) }, ...convo];

    const provider = (Deno.env.get("AI_PROVIDER") || "lovable").toLowerCase();
    const reply = provider === "bedrock" ? await callBedrock(messages) : await callLovable(messages);

    // Extract structured agent actions if present.
    let actions: unknown = null;
    const m = reply.match(/```bloxsmith:actions\s*([\s\S]*?)```/);
    if (m) {
      try {
        actions = JSON.parse(m[1].trim());
      } catch (_) {
        actions = null;
      }
    }

    return new Response(JSON.stringify({ reply, actions, provider, mode }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    const status = (err as { status?: number })?.status ?? 500;
    const msg = (err as { msg?: string })?.msg ?? (err instanceof Error ? err.message : "Unexpected error");
    return new Response(JSON.stringify({ error: msg }), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
