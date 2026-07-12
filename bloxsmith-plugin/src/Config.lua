--[[
	Config.lua
	Central, non-secret configuration for Bloxsmith.
	The backend URL + publishable key are safe to ship inside a plugin — the AI
	provider key lives only on the server. Users can override the URL in Settings.
]]

local Config = {}

Config.Name = "Bloxsmith"
Config.Version = "1.3.0"

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
