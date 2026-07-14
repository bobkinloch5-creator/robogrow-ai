
--[[
	Config.lua
	Central, non-secret configuration for Bloxsmith.
	The backend URL + publishable key are safe to ship inside a plugin — the AI
	provider key lives only on the server. Users can override the URL in Settings.
]]

local Config = {}

Config.Name = "Bloxsmith"
Config.Version = "3.9.3"

-- Changelog shown inside the plugin (newest first).
Config.Changelog = {
	{
		version = "3.9.3",
		date = "2026-07-13",
		title = "Fixed the Wand Button & a Plugin Load Error",
		changes = {
			"FIXED: The 🪄 wand (prompt optimizer) called a backend mode that was never implemented, so it got stuck spinning forever with no result. It now runs through the same chat pipeline as regular messages, so it actually returns an improved prompt.",
			"FIXED: The wand button can no longer get permanently stuck on the hourglass — the request is now wrapped so any failure resets the button and shows an error instead of hanging.",
			"FIXED: A bundler bug had duplicated the closing `end` at the end of most modules, which made the plugin fail to load entirely with a script error. Corrected.",
		},
	},

	{
		version = "3.9.2",
		date = "2026-07-13",
		title = "Fixed Invisible Attachment-Based Effects",
		changes = {
			"FIXED: Creating a bare Attachment (e.g. as a container for particle emitters like rain/mist/splash) directly under Workspace or a Folder silently failed to render, since Attachments only have a valid position when parented to a BasePart. Bloxsmith now automatically gives it an anchored, invisible host Part instead, so it and everything parented under it actually show up.",
			"IMPROVED: The particle/light/beam auto-host check now also verifies an existing Attachment parent is itself properly attached to a BasePart, instead of assuming any Attachment is a valid host.",
		},
	},

	{
		version = "3.9.1",
		date = "2026-07-13",
		title = "Faster Scans & Complete Cache Invalidation",
		changes = {
			"OPTIMIZED: Security and Performance scanners now walk the project tree once instead of twice, roughly halving scan time on large places.",
			"IMPROVED: Security/Performance/Cleanup scans and the Health dashboard's 'Compute' button now run off the main thread, so clicking them no longer visibly freezes Studio on big projects.",
			"FIXED: The project-hierarchy cache (added in 3.9.0) is now invalidated after every DataModel mutation — including Reset Place, quick-action edits, and Toolbox inserts — not just Agent-approved actions, so the AI never sees a stale hierarchy.",
		},
	},

	{
		version = "3.9.0",
		date = "2026-07-13",
		title = "Faster Generation & Safer Action Parsing",
		changes = {
			"IMPROVED: The 'thinking' indicator now appears the instant you hit Send instead of after the project-hierarchy scan — context building moved off the critical path.",
			"OPTIMIZED: Project hierarchy scans (used by Agent/Generate modes) are now cached for a few seconds instead of re-walking the whole place on every message, cutting latency on large projects.",
			"FIXED: The action-JSON safety-net parser no longer blindly swaps every apostrophe for a quote — it's now quote-aware, so generated code containing apostrophes (e.g. \"it's\", \"player's Tool\") is no longer corrupted when the model uses single-quoted JSON.",
			"IMPROVED: Malformed action JSON now also gets a trailing-comma repair pass before falling back to quote repair, catching more model slip-ups without any downside.",
		},
	},

	{
		version = "3.8.0",
		date = "2026-07-13",
		title = "Action JSON Debugging",
		changes = {
			"NEW: Enabled detailed JSON decode error logging for the action parser to easily pinpoint syntax errors from the model.",
		},
	},

	{
		version = "3.7.9",
		date = "2026-07-13",
		title = "Self-Healing & Debug Logging",
		changes = {
			"NEW: Added a clickable '🔁 Retry Request' action directly inside request error bubbles to easily resend failed prompts.",
			"NEW: Added an automatic '🔧 Auto-Fix Exec Error' self-healing option on any script execution failure.",
			"NEW: Enabled detailed backend HTTP error printing in the Studio Output window to help diagnose API/network blocks.",
		},
	},

	{
		version = "3.7.8",
		date = "2026-07-13",
		title = "Smart Chat History Optimization",
		changes = {
			"OPTIMIZED: Automatically compress conversation history when it exceeds 8,000 characters, pruning heavy historical code blocks from older turns while keeping the latest turns intact.",
			"IMPROVED: Significantly reduced LLM input processing times and API latency during extended chat sessions.",
		},
	},

	{
		version = "3.7.7",
		date = "2026-07-13",
		title = "Long Prompt Input Improvements",
		changes = {
			"NEW: Enabled `TextWrapped = true` on all chat and quick-action prompt textboxes, allowing multi-line prompts to wrap and scroll correctly.",
			"IMPROVED: Expanded the height of the main chat input field and optimized scroll layout offsets to comfortably fit long paragraph prompts.",
		},
	},

	{
		version = "3.7.6",
		date = "2026-07-13",
		title = "Robust JSON & Actions Parsing",
		changes = {
			"FIXED: Automatically fix LLM single-quote JSON generation errors to ensure the action checklist renders correctly.",
			"FIXED: Ensured that `bloxsmith:actions` blocks are always stripped from the chat bubble even if JSON parsing fails.",
		},
	},

	{
		version = "3.7.5",
		date = "2026-07-13",
		title = "Performance & Generation Speedups",
		changes = {
			"IMPROVED: Noticeably accelerated AI response times by instructing the model to be extremely concise and direct.",
			"OPTIMIZED: Excluded the project tree hierarchy from chat, explanation, optimization, and fix request payloads, saving network bandwidth and local serialization times.",
		},
	},

	{
		version = "3.7.4",
		date = "2026-07-13",
		title = "Instant Code Execution Support",
		changes = {
			"NEW: Added 'Execute / Run Code' option directly to all generated Lua/Luau script cards, running code immediately in Studio's command-line context.",
			"NEW: Fully integrated with Studio's ChangeHistoryService, enabling complete Ctrl+Z undo support for executed scripts.",
		},
	},

	{
		version = "3.7.3",
		date = "2026-07-13",
		title = "Markdown Parsing & UI Fixes",
		changes = {
			"FIXED: Corrected Lua pattern matching in code blocks to support multiline extraction using `[%s%S]-` instead of `.`, fixing raw JSON blocks displaying in chat.",
			"FIXED: Completely strip proposed action blocks from the chat bubble to keep chat clean and display them solely in the checklist interface.",
		},
	},

	{
		version = "3.7.2",
		date = "2026-07-13",
		title = "Smart Pathing & Code Sanitization",
		changes = {
			"NEW: Added smart path normalization to support dot notation (game.ServerScriptService) and strip redundant file extensions.",
			"NEW: Automatically sanitize AI-generated code to strip leaked markdown code block wrappers (```lua).",
			"IMPROVED: Intelligent script type coercion (automatically converting Scripts to LocalScripts in UI/client containers and vice-versa).",
		},
	},

	{
		version = "3.7.1",
		date = "2026-07-13",
		title = "Flawless Scripting & Quality Standards",
		changes = {
			"NEW: Embedded strict Roblox Luau scripting standards into the AI generator, ensuring all generated scripts are secure, modern, performant, and error-free.",
			"IMPROVED: Increased custom instruction limit to 5000 characters and combined system instructions with user preferences.",
		},
	},

	{
		version = "3.7.0",
		date = "2026-07-13",
		title = "Private Access & No Limits",
		changes = {
			"NEW: Bloxsmith is now private — it only works for the Roblox accounts the owner has approved, tied to your own Roblox login. No sign-in or codes needed.",
			"NEW: Removed all rate limiting — approved users can build as much as they want with no cooldowns.",
			"IMPROVED: If your account isn't approved yet, Bloxsmith now tells you your Roblox ID so you can share it with the owner to get access.",
		},
	},

	{
		version = "3.6.0",
		date = "2026-07-13",
		title = "Faster Responses & Bigger Edits",
		changes = {
			"NEW: Hedged AI requests — if the main model is slow, Bloxsmith now races a fast backup in parallel and returns whichever answers first, so builds come back noticeably quicker.",
			"IMPROVED: A slow or stuck main model no longer blocks your whole request — you get an answer in seconds instead of waiting for it to time out.",
			"IMPROVED: Bloxsmith can now see up to 40 selected objects at once (was 12), so multi-part edits work across much larger selections.",
		},
	},

	{
		version = "3.5.0",
		date = "2026-07-13",
		title = "Reliability & Stop Button",
		changes = {
			"FIXED: Builds no longer hang or 'do nothing' — the backend now has a strict time budget and falls back through multiple AI models fast, so you always get a response.",
			"NEW: Multi-model failover — if the main AI is busy, Bloxsmith instantly retries on backup models (Nemotron, GPT-OSS, DeepSeek) and finally ChatGPT.",
			"NEW: The Send button turns into a ⛔ Stop button while a build runs — tap it any time to stop instantly and free the UI.",
			"IMPROVED: Fallback models run in fast mode so responses come back well within Studio's request limit.",
		},
	},


	{
		version = "3.4.0",
		date = "2026-07-13",
		title = "Plans, Presets & Auto-fix",
		changes = {
			"NEW: Every build now shows a live plan checklist that ticks off ✅/❌ step-by-step as it applies.",
			"NEW: Auto-fix loop — if a build throws an error, Bloxsmith offers a one-tap AI fix, plus a '🔧 Fix latest error' quick chip.",
			"NEW: Prompt quick-actions above the chat input — one-tap Lobby, Leaderboard, Day-night cycle, Teleport pads and Coin pickups.",
			"NEW: Toolbox favorites (☆/⭐) — pin models to a favorites strip for instant re-insert.",
			"NEW: Toolbox 'Insert all results' to drop an entire search at once.",
			"NEW: Save prompt presets in Tools and reload them with one tap.",
			"NEW: First-run guided tour, and a live ⏱ elapsed timer while builds run.",
		},
	},

	{
		version = "3.3.0",
		date = "2026-07-13",
		title = "Selection Edits, Recents & Cancel",
		changes = {
			"NEW: Selection-aware quick edits in Chat — Bigger, Smaller, Duplicate, Anchor and Delete act instantly on whatever's selected in Studio (one Ctrl+Z undoes each).",
			"NEW: Toolbox now remembers recently inserted models so you can re-drop them with one click.",
			"NEW: Toolbox category filters (Models, Vehicles, Buildings, Nature, Weapons) to narrow searches fast.",
			"NEW: Cancel button on in-flight builds — abandon a long request and get the UI back immediately.",
		},
	},

	{
		version = "3.2.2",
		date = "2026-07-12",
		title = "Action Parser Backup",
		changes = {
			"FIXED: If the backend sends an apply block but forgets the structured actions field, the plugin now extracts and shows the Apply button itself.",
			"IMPROVED: Build requests are much less likely to look like they did nothing after Bloxsmith responds.",
		},
	},

	{
		version = "3.2.1",
		date = "2026-07-12",
		title = "Generate Executes Again",
		changes = {
			"FIXED: Empty AI replies no longer leave blank Bloxsmith message bubbles — the plugin now treats them as retryable backend failures.",
			"FIXED: Generate mode now uses the build agent path, so map/visual requests produce apply-ready Studio changes instead of only text.",
			"IMPROVED: If actions are returned with little text, Bloxsmith still shows a clear approval prompt.",
		},
	},

	{
		version = "3.2.0",
		date = "2026-07-12",
		title = "Effects That Actually Work",
		changes = {
			"NEW: Particle effects, fire, smoke, sparkles, beams and trails now auto-attach to a proper host part so they actually render — no more invisible effects.",
			"NEW: Lights (point/spot/surface) and decals/textures also get a visible host so you see them instantly.",
			"IMPROVED: AI-generated effects placed loosely are automatically hosted and ground-placed too, not just Toolbox inserts.",
			"IMPROVED: Effect hosts are anchored, collision-free and camera-focused so nothing gets in your way.",
		},
	},

	{
		version = "3.1.2",
		date = "2026-07-12",
		title = "Smart Ground Placement",
		changes = {
			"NEW: Inserted models now snap to the ground with a downward raycast — no more floating in the air or sinking underground.",
			"IMPROVED: Assets are placed just in front of you, sitting flush on the surface, with the camera auto-framing them.",
			"IMPROVED: Placement accounts for each model's real size so its base rests exactly on the floor.",
		},
	},

	{
		version = "3.1.1",
		date = "2026-07-12",
		title = "Insert Anything Fix",
		changes = {
			"FIXED: Skyboxes now insert into Lighting (not Workspace) so you actually SEE the sky change.",
			"FIXED: Atmosphere, clouds and post-effects (bloom, blur, color correction, sun rays, depth of field) route into Lighting so they take effect.",
			"IMPROVED: Inserts now tell you exactly where the asset landed and auto-focus the camera on visible models.",
		},
	},

	{
		version = "3.1.0",
		date = "2026-07-12",
		title = "Persistent Memory",
		changes = {
			"NEW: Bloxsmith now remembers your conversation across plugin reloads and Studio restarts — it picks up right where you left off.",
			"NEW: Your active chat auto-saves after every message, so nothing is lost if Studio closes.",
			"IMPROVED: Clearing the chat still archives it to History and starts a clean, empty memory.",
		},
	},
	{
		version = "3.0.1",
		date = "2026-07-12",
		title = "Toolbox Insert Fix",
		changes = {
			"FIXED: Toolbox models now use Roblox Studio's plugin insert path so free/public Creator Store models can actually insert into your game.",
			"IMPROVED: If Roblox blocks an asset, Bloxsmith explains that the asset is private/restricted instead of silently failing.",
		},
	},

	{
		version = "3.0.0",
		date = "2026-07-12",
		title = "The Big Build Update",
		changes = {
			"NEW: Real Roblox model thumbnails now render in the Toolbox search.",
			"NEW: Amazing UI generation — vibrant cartoony game look by default, with gradients, strokes, shadows, hover/press + entrance animations.",
			"NEW: The AI can build full animated loading / splash screens with progress bars and spinners.",
			"NEW: In-plugin Changelog tab (you're reading it!).",
			"IMPROVED: AI replies are noticeably faster (same AI, tuned for speed).",
			"IMPROVED: Builds now show live in Edit mode, not just Play mode.",
		},
	},
	{
		version = "2.0.0",
		date = "2026-07-12",
		title = "Agent & Cleanup",
		changes = {
			"NEW: Refresh button clears scripts, assets and instances while keeping the Baseplate.",
			"NEW: Multi-step build agent can create instances, effects and full systems.",
			"IMPROVED: Cleaner chat formatting (proper bold, headers and bullets).",
		},
	},
	{
		version = "1.3.0",
		date = "2026-07-11",
		title = "Foundations",
		changes = {
			"NEW: Secure backend proxy — no AI keys ever ship in the plugin.",
			"NEW: Toolbox search, Analysis, Health and Errors tools.",
			"NEW: Customizable persona, response length and custom instructions.",
		},
	},
}

-- Secure backend (Lovable Cloud edge function). Overridable via plugin settings.
Config.DefaultBackendUrl =
	"https://kxvblxlyawnozipeehnl.supabase.co/functions/v1/bloxsmith-ai"

-- Publishable (anon) key — safe to embed; grants no privileged access.
Config.PublishableKey =
	"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4dmJseGx5YXdub3ppcGVlaG5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzOTkzOTAsImV4cCI6MjA2Nzk3NTM5MH0.JxGkpgvBECagn3eMnG1cN1Io2f20bfUmUq5e-vJqJzY"

Config.RequestTimeout = 60
Config.MaxContextInstances = 400 -- cap hierarchy walk for performance
Config.MaxSelectionContext = 40 -- how many selected instances the AI can see at once

-- Persisted setting keys
Config.Settings = {
	BackendUrl = "bloxsmith_backend_url",
	AutoContext = "bloxsmith_auto_context",
	Persona = "bloxsmith_persona",
	ResponseLength = "bloxsmith_response_length",
	CustomInstructions = "bloxsmith_custom_instructions",
}

-- Customization options exposed in Settings and sent to the secure backend.
Config.Personas = { "Professional", "Friendly", "Teacher", "Concise", "Creative" }
Config.ResponseLengths = { "Brief", "Balanced", "Detailed" }
Config.Defaults = {
	Persona = "Professional",
	ResponseLength = "Balanced",
	CustomInstructions = "",
}
Config.MaxCustomInstructions = 5000

return Config
end

