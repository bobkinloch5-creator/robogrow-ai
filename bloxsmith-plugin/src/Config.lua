--[[
	Config.lua
	Central, non-secret configuration for Bloxsmith.
	The backend URL + publishable key are safe to ship inside a plugin — the AI
	provider key lives only on the server. Users can override the URL in Settings.
]]

local Config = {}

Config.Name = "Bloxsmith"
Config.Version = "3.5.0"

-- Changelog shown inside the plugin (newest first).
Config.Changelog = {
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
	"https://mgdyhoilpgpmyyqulcbr.supabase.co/functions/v1/bloxsmith-ai"

-- Publishable (anon) key — safe to embed; grants no privileged access.
Config.PublishableKey =
	"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nZHlob2lscGdwbXl5cXVsY2JyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNzU3MzUsImV4cCI6MjA3Nzg1MTczNX0.LpDaw0P-Pr-ika8I0opI5nfhyav9EjYahsOo1O7YDqM"

Config.RequestTimeout = 60
Config.MaxContextInstances = 400 -- cap hierarchy walk for performance

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
Config.MaxCustomInstructions = 1000

return Config
