--[[
	Config.lua
	Central, non-secret configuration for Bloxsmith.
	The backend URL + publishable key are safe to ship inside a plugin — the AI
	provider key lives only on the server. Users can override the URL in Settings.
]]

local Config = {}

Config.Name = "Bloxsmith"
Config.Version = "3.0.1"

-- Changelog shown inside the plugin (newest first).
Config.Changelog = {
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
