--[[
	Bloxsmith — AI Copilot for Roblox Studio (single-file build)
	Generated from src/ by bundle.py. Save this as a Local Plugin in Studio.
	Plugins tab -> right-click this file -> Save as Local Plugin, or drop it
	into your Plugins Folder. No Rojo required.

	Copyright (c) Bloxsmith. All rights reserved.
	This plugin and its source code are the exclusive property of Bloxsmith and are
	protected by copyright law. Unauthorized copying, redistribution, resale, or
	reproduction of any part of this software is strictly prohibited. Bloxsmith is
	not affiliated with or endorsed by Roblox Corporation. See https://www.bloxsmiths.xyz
]]

local _modules = {}
local _cache = {}
local function _R(name)
	local cached = _cache[name]
	if cached ~= nil then return cached.value end
	local factory = _modules[name]
	if not factory then error("[Bloxsmith] module not found: " .. tostring(name)) end
	local value = factory()
	_cache[name] = { value = value }
	return value
end

_modules["Config"] = function()

--[[
	Config.lua
	Central, non-secret configuration for Bloxsmith.
	The backend URL + publishable key are safe to ship inside a plugin — the AI
	provider key lives only on the server. Users can override the URL in Settings.
]]

local Config = {}

Config.Name = "Bloxsmith"
Config.Version = "3.9.2"

-- Changelog shown inside the plugin (newest first).
Config.Changelog = {
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

_modules["Services.AIService"] = function()

--[[
	AIService.lua
	The scalable service layer between the plugin and the AI backend.
	- Provider-agnostic: the backend decides which model/provider answers.
	- Secure: no API key is stored here; only the public backend URL + anon key.
	- Robust: full error handling, timeouts, typed results, and automatic
	  retries with exponential backoff for transient failures.
]]
local HttpService = game:GetService("HttpService")

local Config = _R("Config")
local Log = _R("Util.Log")

local AIService = {}
AIService.__index = AIService

local MAX_RETRIES = 4 -- total attempts = MAX_RETRIES + 1 (was 2 — bigger generations need more chances)
local RETRYABLE_STATUS = { [408] = true, [409] = true, [429] = true, [500] = true, [502] = true, [503] = true, [504] = true, [522] = true, [524] = true }
-- 408/522/524 added: Cloudflare timeout-style statuses that show up on slow/large generations.

-- The logged-in Studio user's Roblox account id. Used by the backend allow-list
-- so only accounts the owner authorized can use Bloxsmith. Returns 0 if unknown.
local function getRobloxUserId()
	local ok, id = pcall(function()
		return game:GetService("StudioService"):GetUserId()
	end)
	if ok and type(id) == "number" then
		return id
	end
	return 0
end

function AIService.new(plugin)
	local self = setmetatable({}, AIService)
	self.plugin = plugin
	return self
end

function AIService:getUrl()
	return self.plugin:GetSetting(Config.Settings.BackendUrl) or Config.DefaultBackendUrl
end

function AIService:setUrl(url)
	self.plugin:SetSetting(Config.Settings.BackendUrl, url)
end

-- Reads the user's saved customization (persona, response length, custom
-- instructions) so every request carries the developer's preferences.
function AIService:getPreferences()
	local get = function(key, default)
		local v = self.plugin:GetSetting(key)
		if v == nil or v == "" then
			return default
		end
		return v
	end
	local userInstructions = get(Config.Settings.CustomInstructions, "")
	local systemInstructions = [[
- Core Scripting Standards: Always write clean, modern, secure, and highly-performant Roblox Luau.
- Use Modern task library: Use task.wait(), task.spawn(), task.delay(), and task.defer() instead of wait(), spawn(), delay(), and defer().
- Explicit Services: Always use game:GetService("ServiceName") (e.g. game:GetService("Players")) instead of referencing game.Players directly.
- Avoid Deprecated APIs: Use Connect() and Disconnect() with capital C/D. Do not use :Destroy()'s alias :Remove(). Use Debris:AddItem() instead of spawning custom delay destroyers.
- Local Variables: Keep all variables local unless global scope is strictly required. Use local functions.
- Client-Side Safety (WaitForChild): When writing client-side LocalScripts, always use WaitForChild to access workspace or ReplicatedStorage elements, as client instances stream in asynchronously.
- Server-Side Validation: Never trust client parameters. Always validate inputs, types, ranges, and permissions in RemoteEvent / RemoteFunction server-side handlers to prevent exploits.
- Wrap dangerous/async API calls in pcall: Wrap DataStore, HttpService, MessagingService, and game:GetObjects operations in pcall, checking for success and gracefully handling errors.
- Prevent Memory Leaks: Ensure all Event connections are disconnected when no longer needed (e.g., using :Disconnect() or :Once() where appropriate). Destroy instances when they are done.
- Unthrottled Loops: Never use while true do without task.wait() or a yielding signal, otherwise it will crash the client/server.
- State Management: Do not use _G or shared; use ModuleScripts for clean state sharing.
- UI Handling: Set ResetOnSpawn = false for ScreenGuis that need to persist across respawns. Avoid hardcoded offsets/sizes; use scale/aspect ratio constraint for responsive UI design.
- Concise / Fast Generation Mode: Keep explanations extremely short, direct, and focused. Avoid conversational introductions or summaries to maximize generation speed.

]]
	local instructions = systemInstructions
	if type(userInstructions) == "string" and userInstructions ~= "" then
		instructions = instructions .. "\nAdditional user instructions:\n" .. userInstructions
	end
	if type(instructions) == "string" then
		instructions = string.sub(instructions, 1, Config.MaxCustomInstructions)
	end
	return {
		persona = get(Config.Settings.Persona, Config.Defaults.Persona),
		responseLength = get(Config.Settings.ResponseLength, Config.Defaults.ResponseLength),
		customInstructions = instructions,
	}
end

-- Single HTTP attempt. Returns a normalized table describing the outcome.
function AIService:_attempt(body)
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = self:getUrl(),
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["apikey"] = Config.PublishableKey,
				["Authorization"] = "Bearer " .. Config.PublishableKey,
			},
			Body = body,
		})
	end)

	if not success then
		Log.error("HTTP request failed:", response)
		local msg = tostring(response)
		local looksLikeTimeout = msg:find("time") or msg:find("Time") or msg:find("timed out")
		return {
			ok = false,
			retryable = true,
			error = looksLikeTimeout
				and "The request timed out — this can happen on larger generations. Retrying automatically…"
				or "Network error. Enable HTTP requests (allow the permission prompt) and check the backend URL in Settings.",
		}
	end

	local decoded
	local decodeOk = pcall(function()
		decoded = HttpService:JSONDecode(response.Body)
	end)

	if not response.Success then
		local msg = (decodeOk and decoded and decoded.error)
			or ("Backend error " .. tostring(response.StatusCode))
		warn("[Bloxsmith Backend Error]: Status " .. tostring(response.StatusCode) .. " - " .. tostring(msg))
		if decodeOk and decoded and decoded.detail then
			warn("[Bloxsmith Backend Detail]: " .. tostring(decoded.detail))
		end
		-- A 429 against the DAILY quota can't succeed on retry until reset,
		-- so don't burn retries on it — but DO pass the resetAt timestamp
		-- through so the UI can show a live countdown to when it clears.
		local isRateLimit = response.StatusCode == 429
		return {
			ok = false,
			retryable = isRateLimit and false or (RETRYABLE_STATUS[response.StatusCode] == true),
			error = msg,
			resetAt = decodeOk and decoded and decoded.resetAt or nil,
		}
	end

	if not decodeOk or not decoded then
		warn("[Bloxsmith JSON Decode Error]: Failed to parse response. Body: " .. tostring(response.Body))
		return { ok = false, retryable = false, error = "Received a malformed response from the backend." }
	end

	if decoded.error then
		warn("[Bloxsmith Backend Error]: " .. tostring(decoded.error))
		if decoded.detail then
			warn("[Bloxsmith Backend Detail]: " .. tostring(decoded.detail))
		end
		return { ok = false, retryable = false, error = decoded.error, resetAt = decoded.resetAt }
	end

	if type(decoded.reply) ~= "string" or decoded.reply == "" then
		return {
			ok = false,
			retryable = true,
			error = "The AI returned an empty response. Please try again — Bloxsmith will retry automatically if the backend is busy.",
		}
	end

	return {
		ok = true,
		reply = decoded.reply,
		actions = decoded.actions,
		provider = decoded.provider,
		mode = decoded.mode,
	}
end

--[[
	request(opts) -> result
	opts = { mode, prompt, messages, context }
	result = { ok = bool, reply = string?, actions = table?, error = string? }
	Yields — always call from within task.spawn / a coroutine.
]]
function AIService:request(opts)
	opts = opts or {}
	local payload = {
		mode = opts.mode or "chat",
		prompt = opts.prompt,
		messages = opts.messages,
		context = opts.context,
		preferences = opts.preferences or self:getPreferences(),
		robloxUserId = getRobloxUserId(),
	}

	local ok, body = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		return { ok = false, error = "Failed to encode request." }
	end

	local result
	for attempt = 0, MAX_RETRIES do
		result = self:_attempt(body)
		if result.ok or not result.retryable then
			break
		end
		if attempt < MAX_RETRIES then
			local backoff = 1.2 * (2 ^ attempt) -- was 0.8 — gives slow/large generations more room to finish
			Log.warn(("Transient failure, retrying in %.1fs (attempt %d/%d)…"):format(backoff, attempt + 1, MAX_RETRIES))
			task.wait(backoff)
		end
	end

	if not result.ok and result.retryable then
		result.error = (result.error or "Request failed") .. (" (failed after %d attempts)"):format(MAX_RETRIES + 1)
	end

	return result
end

--[[
	searchToolbox(query) -> { ok, results = { {id, name, creator, thumbnail}... }, error? }
	Searches the Roblox Toolbox (free models) through the secure backend.
	Yields — call from within task.spawn / a coroutine.
]]
function AIService:searchToolbox(query, limit)
	local ok, body = pcall(function()
		return HttpService:JSONEncode({ mode = "toolbox_search", query = query, limit = limit, robloxUserId = getRobloxUserId() })
	end)
	if not ok then
		return { ok = false, error = "Failed to encode search." }
	end

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = self:getUrl(),
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["apikey"] = Config.PublishableKey,
				["Authorization"] = "Bearer " .. Config.PublishableKey,
			},
			Body = body,
		})
	end)

	if not success then
		return { ok = false, error = "Network error. Enable HTTP requests and check the backend URL." }
	end

	local decoded
	local decodeOk = pcall(function()
		decoded = HttpService:JSONDecode(response.Body)
	end)

	if not response.Success then
		local msg = (decodeOk and decoded and decoded.error) or ("Search failed (" .. tostring(response.StatusCode) .. ")")
		return { ok = false, error = msg }
	end
	if not decodeOk or not decoded then
		return { ok = false, error = "Malformed search response." }
	end
	if decoded.error then
		return { ok = false, error = decoded.error }
	end

	return { ok = true, results = decoded.results or {} }
end

return AIService
end

_modules["Services.ApplyService"] = function()

--[[
	ApplyService.lua
	Applies AI-generated changes to the DataModel with full undo/redo support.
	Every batch is wrapped in a ChangeHistoryService recording so a single Ctrl+Z
	reverts the whole operation. Nothing here runs without explicit user approval
	from the UI layer.

	Supported actions (see also the agent prompt in the backend):
	  create_script    { path, name, class, source }
	  replace_script   { target (full path), source }
	  create_folder    { path, name }
	  create_instance  { path, class (ANY creatable Roblox class), name, properties? }
	  set_property      { target, property, value }
	  rename_instance  { target, name }
	  delete_instance  { target }
	  move_instance    { target, path }

	create_instance can build anything Roblox allows — GUIs, parts, models, lights,
	particles, sounds, constraints, tools and more — with rich property coercion
	(Color3, Vector2/3, UDim/UDim2, Rect, NumberRange, ColorSequence, Enums, etc.).
]]
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local InsertService = game:GetService("InsertService")

local Log = _R("Util.Log")

local ApplyService = {}
ApplyService.__index = ApplyService

local SCRIPT_CLASSES = { Script = true, LocalScript = true, ModuleScript = true }

-- Bloxsmith can build ANYTHING Roblox allows. Rather than a narrow whitelist,
-- we allow every creatable class and only refuse a small set that is dangerous,
-- editor-only, or nonsensical to spawn from an AI action. Anything Instance.new
-- can't actually create is caught by the pcall in create_instance.
local CREATE_BLACKLIST = {
	-- Services / singletons (never Instance.new these)
	Workspace = true, Players = true, Lighting = true, ReplicatedStorage = true,
	ServerStorage = true, ServerScriptService = true, StarterGui = true,
	StarterPack = true, StarterPlayer = true, Teams = true, SoundService = true,
	Chat = true, LocalizationService = true, TestService = true, CoreGui = true,
	-- Dangerous / abusable
	Player = true, Message = true, Hint = true, DataStoreService = true,
}


local function sanitizeName(name)
	if type(name) ~= "string" then
		return name
	end
	return name:gsub("%.lua$", ""):gsub("%.LUA$", "")
end

local function sanitizeSource(src)
	if type(src) ~= "string" then
		return src
	end
	local clean = src:gsub("^%s+", ""):gsub("%s+$", "")
	if string.sub(clean, 1, 3) == "```" then
		clean = clean:gsub("^```%w*%s*", "")
		clean = clean:gsub("%s*```$", "")
	end
	return clean
end

function ApplyService.new(contextService)
	return setmetatable({ contextService = contextService }, ApplyService)
end

-- Any DataModel mutation invalidates the cached project-tree so the AI's
-- next look at the hierarchy is never stale. Centralized here (rather than
-- at each UI call site) so no future mutation path can forget it.
function ApplyService:_invalidateContext()
	if self.contextService then
		self.contextService:invalidateTreeCache()
	end
end

-- Resolve "ServerScriptService/Systems/Shop" or dot-notated paths into an Instance, creating folders as needed.
function ApplyService:resolvePath(path, createFolders)
	if type(path) ~= "string" or path == "" then
		return nil
	end
	-- Strip .lua extension from end if present (e.g. "Script.lua" -> "Script")
	local cleanPath = path:gsub("%.lua$", ""):gsub("%.LUA$", "")
	-- Normalize separators: change dots and backslashes to slashes.
	local normalized = cleanPath:gsub("%.", "/"):gsub("\\", "/")
	-- Strip leading/trailing slashes and ignore game/ prefix
	normalized = normalized:gsub("^/+", ""):gsub("/+$", "")
	if string.sub(normalized, 1, 5) == "game/" then
		normalized = string.sub(normalized, 6)
	end
	
	local segments = string.split(normalized, "/")
	local serviceName = segments[1]
	local ok, current = pcall(function()
		return game:GetService(serviceName)
	end)
	if not ok or not current then
		-- Fall back to a child of Workspace by name.
		current = workspace:FindFirstChild(serviceName) or workspace
	end
	for i = 2, #segments do
		local segname = segments[i]
		if segname ~= "" then
			local nextInst = current:FindFirstChild(segname)
			if not nextInst then
				if not createFolders then
					return nil
				end
				-- Only the LAST segment of a path is a folder Bloxsmith is
				-- meant to create fresh (e.g. "Workspace/NewFolder"). A
				-- missing MIDDLE segment almost always means a previous
				-- action's exact name didn't match (typo, renamed by the
				-- attachment-host fix, case difference, etc). Silently
				-- spawning a substitute Folder here used to cause effects
				-- like rain to get parented into an empty, wrongly-placed
				-- Folder instead of the real host — with no visible error.
				-- Fail loudly instead so the caller can react (or so this
				-- shows up in logs) rather than rain silently not falling.
				if i < #segments then
					Log.warn(("resolvePath: missing intermediate segment '%s' in '%s' — refusing to substitute a Folder, since a later effect could get silently mis-parented."):format(segname, path))
					return nil
				end
				nextInst = Instance.new("Folder")
				nextInst.Name = segname
				nextInst.Parent = current
			end
			current = nextInst
		end
	end
	return current
end

-- Parse a color from {r,g,b} (0-255), {number,number,number} (0-1), or "#RRGGBB".
local function parseColor(value)
	if type(value) == "string" then
		local hex = value:gsub("#", "")
		if #hex == 6 then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			if r and g and b then return Color3.fromRGB(r, g, b) end
		end
		return nil
	elseif type(value) == "table" then
		local r = value.r or value.R or value[1] or 0
		local g = value.g or value.G or value[2] or 0
		local b = value.b or value.B or value[3] or 0
		-- Values <= 1 are treated as normalized floats, otherwise 0-255.
		if r <= 1 and g <= 1 and b <= 1 then
			return Color3.new(r, g, b)
		end
		return Color3.fromRGB(r, g, b)
	end
	return nil
end

-- Best-effort coercion of a JSON value into a Roblox property value.
-- Handles the full range of common Roblox datatypes so the agent can set
-- virtually any property (parts, GUIs, constraints, effects, values...).
local function coerceValue(inst, property, value)
	local ok, existing = pcall(function() return inst[property] end)
	if not ok then return value end
	local t = typeof(existing)

	if t == "Color3" then
		return parseColor(value) or existing
	elseif t == "BrickColor" then
		if type(value) == "string" then
			local okBC, bc = pcall(BrickColor.new, value)
			if okBC then return bc end
		end
		local c = parseColor(value)
		if c then return BrickColor.new(c) end
		return existing
	elseif t == "Vector3" and type(value) == "table" then
		return Vector3.new(value.x or value[1] or 0, value.y or value[2] or 0, value.z or value[3] or 0)
	elseif t == "Vector2" and type(value) == "table" then
		return Vector2.new(value.x or value[1] or 0, value.y or value[2] or 0)
	elseif t == "UDim2" and type(value) == "table" then
		-- Accept {sx,ox,sy,oy} or {x={scale,offset},y={scale,offset}}
		if value.x or value.X then
			local x, y = value.x or value.X, value.y or value.Y
			return UDim2.new(x[1] or x.scale or 0, x[2] or x.offset or 0, y[1] or y.scale or 0, y[2] or y.offset or 0)
		end
		return UDim2.new(value[1] or 0, value[2] or 0, value[3] or 0, value[4] or 0)
	elseif t == "UDim" and type(value) == "table" then
		return UDim.new(value[1] or value.scale or 0, value[2] or value.offset or 0)
	elseif t == "Vector2int16" and type(value) == "table" then
		return Vector2int16.new(value[1] or 0, value[2] or 0)
	elseif t == "CFrame" and type(value) == "table" then
		return CFrame.new(value[1] or 0, value[2] or 0, value[3] or 0)
	elseif t == "Rect" and type(value) == "table" then
		return Rect.new(value[1] or 0, value[2] or 0, value[3] or 0, value[4] or 0)
	elseif t == "NumberRange" and type(value) == "table" then
		return NumberRange.new(value[1] or value.min or 0, value[2] or value.max or value[1] or 0)
	elseif t == "ColorSequence" then
		local c = parseColor(value)
		if c then return ColorSequence.new(c) end
		if type(value) == "table" and value[1] then
			local kps = {}
			for _, kp in ipairs(value) do
				local col = parseColor(kp.color or kp) or Color3.new(1, 1, 1)
				table.insert(kps, ColorSequenceKeypoint.new(kp.time or kp[1] or 0, col))
			end
			if #kps >= 2 then return ColorSequence.new(kps) end
		end
		return existing
	elseif t == "NumberSequence" then
		if type(value) == "number" then return NumberSequence.new(value) end
		return existing
	elseif t == "number" then
		return tonumber(value) or existing
	elseif t == "boolean" then
		if type(value) == "string" then return value == "true" end
		return value and true or false
	elseif t == "string" then
		return tostring(value)
	elseif t == "EnumItem" and type(value) == "string" then
		-- e.g. "Enum.Material.Neon" or "Neon"
		local enumName = existing.EnumType.Name
		local leaf = string.match(value, "([%w_]+)$") or value
		local okEnum, enumVal = pcall(function()
			return Enum[enumName][leaf]
		end)
		if okEnum then
			return enumVal
		end
	end
	return value
end

local function assetAccessHint(reason)
	reason = tostring(reason or "")
	if string.find(string.lower(reason), "not authorized", 1, true) then
		return "Roblox blocked this asset for this place/account. Bloxsmith tried the plugin insert path too; pick another free/public model or use an asset you own/group-owns."
	end
	return nil
end

local function loadAssetForPlugin(assetId)
	-- Plugins can insert public free Toolbox assets through DataModel:GetObjects,
	-- while InsertService:LoadAsset is limited to owned/shared/Roblox assets.
	local contentId = "rbxassetid://" .. tostring(assetId)
	local okObjects, objects = pcall(function()
		return game:GetObjects(contentId)
	end)
	if okObjects and type(objects) == "table" and #objects > 0 then
		return true, objects, "GetObjects"
	end

	local getObjectsError = tostring(objects or "GetObjects returned no objects")
	local okLoad, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if okLoad and loaded then
		return true, loaded:GetChildren(), "LoadAsset", loaded
	end

	local loadAssetError = tostring(loaded or "LoadAsset returned nothing")
	return false, getObjectsError .. " / " .. loadAssetError
end

-- Decide the correct container for an inserted object based on its class so
-- non-Workspace assets (skies, atmosphere, lighting/post effects, sounds…)
-- actually take effect instead of sitting invisibly in Workspace.
-- Returns (parentInstance, isVisual). isVisual objects get camera-focused.
local function smartParentFor(inst, fallbackParent)
	local function svc(name)
		local ok, s = pcall(function() return game:GetService(name) end)
		return ok and s or nil
	end

	-- Sky, Atmosphere, Clouds and all post-processing effects live in Lighting.
	local LIGHTING_CLASSES = {
		Sky = true, Atmosphere = true, Clouds = true,
		BloomEffect = true, BlurEffect = true, ColorCorrectionEffect = true,
		DepthOfFieldEffect = true, SunRaysEffect = true,
	}
	if inst:IsA("PostEffect") or inst:IsA("Sky") or inst:IsA("Atmosphere")
		or LIGHTING_CLASSES[inst.ClassName] then
		return svc("Lighting") or fallbackParent, false
	end

	-- Sounds default to SoundService (or wherever the user pointed).
	if inst:IsA("Sound") then
		return fallbackParent or svc("SoundService") or workspace, false
	end

	-- Visible geometry belongs in Workspace and should be focused.
	if inst:IsA("Model") or inst:IsA("BasePart") or inst:IsA("Folder") then
		return fallbackParent or workspace, true
	end

	-- Everything else (scripts, values, animations, decals, GUIs…) goes to the
	-- requested path (Workspace by default) — not visual, just placed.
	return fallbackParent or workspace, false
end

-- Snap a Model/BasePart onto the ground in front of the camera so inserted
-- assets rest ON the surface — never floating in the air or buried underground.
-- Uses a downward raycast (ignoring the object itself + other freshly-inserted
-- objects) and offsets by the object's bounding box so its base sits flush.
local function placeOnGround(obj, camera, ignoreList)
	if not (obj:IsA("Model") or obj:IsA("BasePart")) then
		return
	end

	-- Bounding box (world-space center + size) and current pivot.
	local pivot = obj:GetPivot()
	local boxCF, size
	if obj:IsA("Model") then
		local okBox, cf, sz = pcall(function()
			local c, s = obj:GetBoundingBox()
			return c, s
		end)
		-- pcall returns (true, cf, sz)
		if okBox then boxCF, size = cf, sz end
	else
		boxCF, size = obj.CFrame, obj.Size
	end
	if not boxCF or not size then
		return
	end

	-- Target X/Z: a bit in front of the camera on the horizontal plane.
	local targetX, targetZ = 0, 0
	if camera then
		local fwd = camera.CFrame.LookVector
		local flat = Vector3.new(fwd.X, 0, fwd.Z)
		if flat.Magnitude < 0.01 then
			flat = Vector3.new(0, 0, -1)
		end
		flat = flat.Unit
		local dist = math.max(size.X, size.Z) * 0.5 + 16
		local aim = camera.CFrame.Position + flat * dist
		targetX, targetZ = aim.X, aim.Z
	end

	-- Raycast straight down to find the surface, ignoring the object itself.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { obj }
	if type(ignoreList) == "table" then
		for _, o in ipairs(ignoreList) do
			table.insert(ignore, o)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true

	local origin = Vector3.new(targetX, 10000, targetZ)
	local hit = workspace:Raycast(origin, Vector3.new(0, -20000, 0), params)
	local groundY = hit and hit.Position.Y or 0 -- default to baseplate plane (y=0)

	-- Offset needed to move the bounding box: center to target X/Z, base to ground.
	local offset = Vector3.new(
		targetX - boxCF.Position.X,
		(groundY + size.Y * 0.5 + 0.05) - boxCF.Position.Y,
		targetZ - boxCF.Position.Z
	)

	pcall(function()
		obj:PivotTo(pivot + offset)
	end)
end

-- Visual effects that only render when parented to a BasePart/Attachment.
-- Inserted or created on their own they'd be invisible, so Bloxsmith gives them
-- a proper anchored host part so they actually show up in the game.
local EFFECT_CLASSES = {
	ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true,
	Beam = true, Trail = true, Decal = true, Texture = true, PointLight = true,
	SpotLight = true, SurfaceLight = true,
}

local function isEffect(inst)
	return EFFECT_CLASSES[inst.ClassName]
		or inst:IsA("ParticleEmitter") or inst:IsA("Fire") or inst:IsA("Smoke")
		or inst:IsA("Sparkles") or inst:IsA("Beam") or inst:IsA("Trail")
		or inst:IsA("Decal") or inst:IsA("Texture") or inst:IsA("Light")
end

-- Wrap a bare effect in an anchored, collision-free host part (with the right
-- attachments where the effect needs them) and return the host part.
local function createEffectHost(effect)
	local part = Instance.new("Part")
	part.Name = ((effect.Name ~= "" and effect.Name) or effect.ClassName) .. "_FX"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1

	if effect:IsA("Decal") or effect:IsA("Texture") then
		-- Show a decal/texture on a visible panel so it's actually seen.
		part.Size = Vector3.new(4, 4, 0.2)
		part.Transparency = 0
		part.Color = Color3.fromRGB(230, 230, 230)
		pcall(function() effect.Face = Enum.NormalId.Front end)
		effect.Parent = part
	elseif effect:IsA("Beam") or effect:IsA("Trail") then
		local a0 = Instance.new("Attachment")
		a0.Name = "FXAttachment0"
		a0.Parent = part
		local a1 = Instance.new("Attachment")
		a1.Name = "FXAttachment1"
		a1.Position = Vector3.new(0, 4, 0)
		a1.Parent = part
		pcall(function()
			effect.Attachment0 = a0
			effect.Attachment1 = a1
		end)
		effect.Parent = part
	else
		-- ParticleEmitter, Fire, Smoke, Sparkles, Lights: emit from the part.
		effect.Parent = part
	end
	return part
end


-- Apply one action. Returns (ok, message, instance?).

function ApplyService:applyOne(action)
	local kind = action.action

	if kind == "create_folder" then
		local parent = self:resolvePath(action.path or "Workspace", true)
		local name = action.name or "Folder"
		-- The agent is instructed to create folders before every use of a
		-- path, so it commonly re-emits create_folder for the same path
		-- across multiple steps of one plan. Reuse an existing Folder with
		-- this name instead of always spawning a new one, otherwise you end
		-- up with sibling duplicates (e.g. two "DashSystem" folders) and
		-- later steps can land in the wrong copy.
		local existing = parent and parent:FindFirstChild(name)
		if existing and existing:IsA("Folder") then
			return true, "Folder already exists: " .. existing:GetFullName(), existing
		end
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
		return true, "Created folder " .. folder:GetFullName(), folder

	elseif kind == "create_script" then
		local parent = self:resolvePath(action.path or "ServerScriptService", true)
		local class = SCRIPT_CLASSES[action.class] and action.class or "Script"
		
		-- Coerce script class based on parent container for guaranteed execution
		if parent then
			local fullName = parent:GetFullName()
			if class == "Script" then
				if string.find(fullName, "StarterPlayer") or string.find(fullName, "StarterGui") or string.find(fullName, "Players") or string.find(fullName, "ReplicatedStorage") or string.find(fullName, "ReplicatedFirst") then
					class = "LocalScript"
				end
			elseif class == "LocalScript" then
				if string.find(fullName, "ServerScriptService") or string.find(fullName, "ServerStorage") then
					class = "Script"
				end
			end
		end

		local inst = Instance.new(class)
		inst.Name = sanitizeName(action.name or "BloxsmithScript")
		inst.Source = sanitizeSource(action.source) or "-- (empty)"
		inst.Parent = parent
		return true, "Created " .. class .. " " .. inst:GetFullName(), inst

	elseif kind == "replace_script" then
		local target = self:resolvePath(action.target or "", false)
		if not target or not target:IsA("LuaSourceContainer") then
			return false, "Could not find script to replace: " .. tostring(action.target)
		end
		target.Source = sanitizeSource(action.source) or target.Source
		return true, "Updated " .. target:GetFullName(), target

	elseif kind == "create_instance" then
		local class = action.class
		if type(class) ~= "string" or class == "" then
			return false, "create_instance requires a class name"
		end
		if CREATE_BLACKLIST[class] then
			return false, "Refused to create protected/service class: " .. tostring(class)
		end
		local parent = self:resolvePath(action.path or "Workspace", true)

		-- An Attachment only has a valid world position when parented to a
		-- BasePart. If the AI creates one directly under Workspace/a Folder/a
		-- Model, it silently fails to render — and everything hung off it
		-- (particle emitters, beams, lights…) never shows up either. Give it
		-- an anchored, invisible host Part instead, using the requested name,
		-- so follow-up actions targeting this same path still resolve and its
		-- children work correctly parented straight to a real BasePart.
		if class == "Attachment" and parent and not parent:IsA("BasePart") then
			local host = Instance.new("Part")
			host.Name = sanitizeName(action.name or "Attachment")
			host.Anchored = true
			host.CanCollide = false
			host.CanQuery = false
			host.CanTouch = false
			host.CastShadow = false
			host.Transparency = 1
			host.Size = Vector3.new(1, 1, 1)
			if type(action.properties) == "table" then
				for prop, val in pairs(action.properties) do
					pcall(function()
						host[prop] = coerceValue(host, prop, val)
					end)
				end
			end
			host.Parent = parent
			return true, ("Created %s as an anchored host part (Attachments need a BasePart parent to render)"):format(host.Name), host
		end

		local okNew, inst = pcall(Instance.new, class)
		if not okNew or not inst then
			return false, "Roblox cannot create an instance of class: " .. tostring(class)
		end
		inst.Name = sanitizeName(action.name or class)
		if type(action.properties) == "table" then
			for prop, val in pairs(action.properties) do
				pcall(function()
					inst[prop] = coerceValue(inst, prop, val)
				end)
			end
		end

		-- Safety net: GuiObjects (TextButton, TextLabel, Frame, ImageButton,
		-- ScrollingFrame, etc.) and ScreenGuis never render unless they end up
		-- as a descendant of a LayerCollector (ScreenGui/BillboardGui/SurfaceGui)
		-- that itself lives under StarterGui/PlayerGui. The default parent path
		-- above falls back to Workspace when no path is given — harmless for
		-- parts/models, but a button dropped in Workspace is permanently
		-- invisible with no error, which reads as "the plugin isn't creating
		-- buttons." Auto-redirect into a ScreenGui under StarterGui instead so
		-- GUI elements always actually show up.
		if inst:IsA("ScreenGui") then
			local underGui = false
			do
				local p = parent
				while p do
					if p:IsA("LayerCollector") or p.Name == "StarterGui" or p.Name == "PlayerGui" then
						underGui = true
						break
					end
					p = p.Parent
				end
			end
			if not underGui then
				parent = game:GetService("StarterGui")
			end
		elseif inst:IsA("GuiObject") then
			local hasLayerCollector = false
			do
				local p = parent
				while p do
					if p:IsA("LayerCollector") then
						hasLayerCollector = true
						break
					end
					p = p.Parent
				end
			end
			if not hasLayerCollector then
				local gui = Instance.new("ScreenGui")
				gui.Name = "BloxsmithGui"
				gui.ResetOnSpawn = false
				gui.Parent = game:GetService("StarterGui")
				parent = gui
			end
		end

		-- Safety net: a ParticleEmitter/Fire/Smoke can exist, be Enabled, and
		-- still emit nothing VISIBLE if the AI's generated properties left
		-- Rate/Lifetime/Speed at 0 or empty (e.g. an incomplete NumberSequence
		-- for Size, or Rate = 0). This was showing up as "sometimes rain just
		-- doesn't appear" with no error, since the instance itself was created
		-- successfully. Only touch properties the AI actually left broken —
		-- never override values it explicitly and validly set.
		if inst:IsA("ParticleEmitter") then
			pcall(function()
				if inst.Rate <= 0 then inst.Rate = 40 end
				if inst.Lifetime.Min <= 0 and inst.Lifetime.Max <= 0 then
					inst.Lifetime = NumberRange.new(1, 2)
				end
				if inst.Speed.Min <= 0 and inst.Speed.Max <= 0 then
					inst.Speed = NumberRange.new(5, 10)
				end
				if inst.Enabled == nil then inst.Enabled = true end
			end)
		elseif inst:IsA("Fire") or inst:IsA("Smoke") then
			pcall(function()
				if inst.Enabled == false and action.properties and action.properties.Enabled == nil then
					inst.Enabled = true
				end
			end)
		end

		-- Effects (particles, fire, beams, lights, decals…) only render on a
		-- BasePart, or an Attachment that is itself properly parented to one.
		-- If the AI created one loose in a container (or under a broken/
		-- unparented Attachment), give it a visible, ground-placed host part.
		local parentIsValidHost = parent:IsA("BasePart")
			or (parent:IsA("Attachment") and parent.Parent ~= nil and parent.Parent:IsA("BasePart"))
		if isEffect(inst) and not parentIsValidHost then
			local host = createEffectHost(inst)
			pcall(function() host.Parent = parent end)
			pcall(function() placeOnGround(host, workspace.CurrentCamera) end)
			return true, ("Created %s on host part %s"):format(class, host:GetFullName()), host
		end
		inst.Parent = parent
		return true, "Created " .. class .. " " .. inst:GetFullName(), inst


	elseif kind == "set_property" then
		local target = self:resolvePath(action.target or "", false)
		if not target then
			return false, "Could not find target: " .. tostring(action.target)
		end
		local okSet = pcall(function()
			target[action.property] = coerceValue(target, action.property, action.value)
		end)
		if not okSet then
			return false, ("Could not set %s on %s"):format(tostring(action.property), target:GetFullName())
		end
		return true, ("Set %s on %s"):format(tostring(action.property), target:GetFullName()), target

	elseif kind == "rename_instance" then
		local target = self:resolvePath(action.target or "", false)
		if not target then
			return false, "Could not find target: " .. tostring(action.target)
		end
		local old = target:GetFullName()
		target.Name = action.name or target.Name
		return true, ("Renamed %s -> %s"):format(old, target.Name), target

	elseif kind == "move_instance" then
		local target = self:resolvePath(action.target or "", false)
		if not target then
			return false, "Could not find target: " .. tostring(action.target)
		end
		local parent = self:resolvePath(action.path or "Workspace", true)
		target.Parent = parent
		return true, ("Moved %s into %s"):format(target.Name, parent:GetFullName()), target

	elseif kind == "delete_instance" then
		local target = self:resolvePath(action.target or "", false)
		if not target then
			return false, "Could not find target to delete: " .. tostring(action.target)
		end
		local name = target:GetFullName()
		target.Parent = nil
		return true, "Deleted " .. name, nil

	elseif kind == "insert_asset" then
		local assetId = tonumber(action.assetId or action.id)
		if not assetId then
			return false, "insert_asset requires a numeric assetId"
		end
		local requestedParent = self:resolvePath(action.path or "Workspace", true)
		local okLoad, loaded, loaderName, container = loadAssetForPlugin(assetId)
		if not okLoad then
			-- Surface the REAL Roblox error so the user knows what went wrong
			-- (e.g. private model, needs purchase, moderation, offline).
			local hint = assetAccessHint(loaded)
			Log.warn("Asset insert failed for", assetId, ":", loaded)
			return false, ("Could not insert model %d — %s%s"):format(assetId, tostring(loaded), hint and ("\n" .. hint) or "")
		end

		local children = loaded
		-- Route each top-level object to the container Roblox actually needs so
		-- non-Workspace assets (skies, atmospheres, lighting effects, sounds…)
		-- become visible/active instead of silently sitting in Workspace.
		local placed = {}
		local visualParts = {}
		for _, child in ipairs(children) do
			if isEffect(child) then
				-- Give bare effects a visible host part so particles/fire/beams
				-- etc. actually render in the world.
				local host = createEffectHost(child)
				pcall(function() host.Parent = requestedParent or workspace end)
				table.insert(placed, host)
				table.insert(visualParts, host)
			else
				local target, isVisual = smartParentFor(child, requestedParent)
				pcall(function()
					child.Parent = target
				end)
				table.insert(placed, child)
				if isVisual then
					table.insert(visualParts, child)
				end
			end
		end
		if container then pcall(function() container:Destroy() end) end


		if #placed == 0 then
			return false, ("Asset %d loaded but contained nothing to insert."):format(assetId)
		end

		-- Optional custom name (applies to the single inserted object).
		local inserted = placed[1]
		if #placed == 1 and action.name then
			pcall(function() inserted.Name = action.name end)
		end

		-- Ground-snap each visible object in front of the camera so it rests ON
		-- the surface (never floating or buried), then focus the camera on it.
		pcall(function()
			local camera = workspace.CurrentCamera
			local focused = false
			for _, obj in ipairs(visualParts) do
				if obj:IsA("Model") or obj:IsA("BasePart") then
					placeOnGround(obj, camera, visualParts)
					if camera and not focused then
						camera.CFrame = CFrame.lookAt(
							obj:GetPivot().Position + Vector3.new(0, 6, 18),
							obj:GetPivot().Position
						)
						focused = true
					end
				end
			end
		end)


		-- Build a friendly summary that tells the user WHERE it went.
		local dest = placed[1].Parent and placed[1].Parent:GetFullName() or "your game"
		local kindName = placed[1].ClassName
		local note = ""
		if not (placed[1]:IsA("Model") or placed[1]:IsA("BasePart")) then
			note = (" (%s → %s; open Explorer to see it)"):format(kindName, dest)
		end
		return true, ("Inserted %s (asset %d) into %s via %s%s"):format(kindName, assetId, dest, loaderName or "plugin insert", note), inserted
	end



	return false, "Unknown action: " .. tostring(kind)
end

-- Apply a batch of actions inside a single undo waypoint.
function ApplyService:applyActions(actions, label)
	if type(actions) ~= "table" or #actions == 0 then
		return { ok = false, error = "No actions to apply." }
	end

	local recordId = ChangeHistoryService:TryBeginRecording(label or "Bloxsmith change")
	local results = {}
	local created = {}
	local anyFail = false
	local okCount = 0
	local firstError = nil

	for _, action in ipairs(actions) do
		local ok, msg, inst = self:applyOne(action)
		table.insert(results, { ok = ok, message = msg })
		if ok then
			okCount += 1
			if inst then
				table.insert(created, inst)
			end
		else
			anyFail = true
			firstError = firstError or msg
			Log.warn("Action failed:", msg)
		end
	end

	if recordId then
		ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
	end

	if #created > 0 then
		pcall(function()
			Selection:Set(created)
		end)
	end

	self:_invalidateContext()
	return { ok = not anyFail, results = results, created = created, applied = okCount, error = firstError }
end


-- Overwrite a specific script's source with undo support (used by fix/optimize).
function ApplyService:replaceSource(scriptInstance, newSource, label)
	if not scriptInstance or not scriptInstance:IsA("LuaSourceContainer") then
		return { ok = false, error = "No valid script selected." }
	end
	local recordId = ChangeHistoryService:TryBeginRecording(label or "Bloxsmith edit script")
	scriptInstance.Source = sanitizeSource(newSource) or scriptInstance.Source
	if recordId then
		ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
	end
	return { ok = true }
end

-- Insert a Toolbox / Creator Store model by asset id, with undo support.
function ApplyService:insertAsset(assetId, name)
	return self:applyActions(
		{ { action = "insert_asset", assetId = assetId, path = "Workspace", name = name } },
		"Bloxsmith insert asset"
	)
end

-- Wipe the place: remove ALL scripts, models, GUIs and assets across the common
-- containers while keeping the Baseplate (and the un-removable Terrain/Camera).
-- Fully undoable with a single Ctrl+Z via ChangeHistoryService.
function ApplyService:resetPlace(keepBaseplate)
	local recordId = ChangeHistoryService:TryBeginRecording("Bloxsmith reset place")
	local removed = 0

	local function clearContainer(container, protect)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if not (protect and protect(child)) then
				local ok = pcall(function()
					child:Destroy()
				end)
				if ok then
					removed += 1
				end
			end
		end
	end

	-- Workspace: keep Terrain, Camera and the baseplate; remove everything else.
	clearContainer(workspace, function(child)
		if child:IsA("Terrain") or child:IsA("Camera") then
			return true
		end
		if keepBaseplate ~= false and child.Name == "Baseplate" then
			return true
		end
		return false
	end)

	-- Wipe the standard containers entirely.
	local services = {
		"ServerScriptService", "ServerStorage", "ReplicatedStorage",
		"ReplicatedFirst", "StarterGui", "StarterPack", "Lighting",
	}
	for _, name in ipairs(services) do
		local ok, svc = pcall(function()
			return game:GetService(name)
		end)
		if ok and svc then
			clearContainer(svc)
		end
	end

	-- StarterPlayer holds its scripts in sub-containers; clear those, not the
	-- containers themselves (which Roblox recreates/needs).
	local okSP, sp = pcall(function()
		return game:GetService("StarterPlayer")
	end)
	if okSP and sp then
		clearContainer(sp:FindFirstChild("StarterPlayerScripts"))
		clearContainer(sp:FindFirstChild("StarterCharacterScripts"))
	end

	if recordId then
		ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
	end
	self:_invalidateContext()
	return { ok = true, removed = removed }
end

-- Direct, instant edits on the current Studio selection, grouped into a single
-- undo waypoint. Powers the selection-aware quick-action chips in the chat view
-- ("bigger", "smaller", "duplicate", "anchor", "recolor", "delete") so common
-- tweaks don't need a full AI round-trip.
function ApplyService:editSelection(op, arg)
	local sel = Selection:Get()
	if #sel == 0 then
		return { ok = false, error = "Select something in Studio first." }
	end

	local recordId = ChangeHistoryService:TryBeginRecording("Bloxsmith " .. tostring(op) .. " selection")
	local count = 0
	local newSelection = {}

	local function eachPart(inst, fn)
		if inst:IsA("BasePart") then
			fn(inst)
		end
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") then
				fn(d)
			end
		end
	end

	for _, inst in ipairs(sel) do
		pcall(function()
			if op == "scale" then
				local factor = tonumber(arg) or 1
				if inst:IsA("Model") then
					local okScale = pcall(function()
						inst:ScaleTo((inst:GetScale() or 1) * factor)
					end)
					if okScale then
						count += 1
					end
				elseif inst:IsA("BasePart") then
					inst.Size = inst.Size * factor
					count += 1
				end
			elseif op == "anchor" then
				eachPart(inst, function(p)
					p.Anchored = arg and true or false
				end)
				count += 1
			elseif op == "color" then
				local c = parseColor(arg)
				if c then
					eachPart(inst, function(p)
						p.Color = c
					end)
					count += 1
				end
			elseif op == "duplicate" then
				local clone = inst:Clone()
				clone.Parent = inst.Parent
				table.insert(newSelection, clone)
				count += 1
			elseif op == "delete" then
				inst.Parent = nil
				count += 1
			end
		end)
	end

	if recordId then
		ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
	end
	if #newSelection > 0 then
		pcall(function()
			Selection:Set(newSelection)
		end)
	end

	if count == 0 then
		return { ok = false, error = "Nothing in the selection could be edited that way." }
	end
	self:_invalidateContext()
	return { ok = true, count = count }
end

return ApplyService
end

_modules["Services.CleanupService"] = function()

--[[
	CleanupService.lua
	Detects organization issues: default names, duplicates, empty folders,
	and scripts left in the wrong service. Suggestions only — user applies them.
]]
local CleanupService = {}
CleanupService.__index = CleanupService

local DEFAULT_NAMES = {
	Part = true, MeshPart = true, Script = true, LocalScript = true,
	ModuleScript = true, Folder = true, Model = true, Frame = true,
	TextButton = true, TextLabel = true, RemoteEvent = true, Value = true,
}

-- Only scan the same services ContextService shows the AI. Walking the whole
-- DataModel with game:GetDescendants() previously swept in CoreGui, plugin
-- widgets (including Bloxsmith's own UI), InsertService caches and other
-- editor/engine internals — producing false-positive findings that had
-- nothing to do with the user's actual game, and wasting time on a full-tree
-- walk of instances no one can act on anyway.
local INSPECTED_SERVICES = {
	"Workspace", "ServerScriptService", "ServerStorage", "ReplicatedStorage",
	"StarterGui", "StarterPlayer", "StarterPack", "Lighting",
}

function CleanupService.new()
	return setmetatable({}, CleanupService)
end

function CleanupService:scan()
	local findings = {}
	local defaults, emptyFolders = 0, 0
	local nameBuckets = {}

	for _, svcName in ipairs(INSPECTED_SERVICES) do
		local ok, svc = pcall(function()
			return game:GetService(svcName)
		end)
		if ok and svc then
			for _, d in ipairs(svc:GetDescendants()) do
				-- Default-named objects.
				if DEFAULT_NAMES[d.Name] then
					defaults += 1
				end
				-- Empty folders.
				if d:IsA("Folder") and #d:GetChildren() == 0 then
					emptyFolders += 1
					table.insert(findings, {
						severity = "Low",
						title = "Empty folder",
						advice = "Remove or populate this folder.",
						path = d:GetFullName(),
					})
				end
				-- Duplicate sibling names.
				local parent = d.Parent
				if parent then
					local key = parent:GetFullName() .. "|" .. d.Name
					nameBuckets[key] = (nameBuckets[key] or 0) + 1
				end
			end
		end
	end

	if defaults > 0 then
		table.insert(findings, 1, {
			severity = "Medium",
			title = ("%d default-named objects"):format(defaults),
			advice = "Rename generic 'Part'/'Script'/'Folder' instances to describe their purpose.",
		})
	end

	-- Raised from 5 to 12: numbered props, particle-effect parts, and small
	-- groups of NPCs/enemies are common and intentional in real games. A
	-- lower bar was flagging normal game content as a naming problem.
	for key, count in pairs(nameBuckets) do
		if count >= 12 then
			local name = string.split(key, "|")[2]
			table.insert(findings, {
				severity = "Low",
				title = ("%d siblings named '%s'"):format(count, name),
				advice = "Large groups of identically named siblings are hard to navigate — consider a numbered scheme or a folder.",
				path = string.split(key, "|")[1],
			})
		end
	end

	return findings
end

return CleanupService
end

_modules["Services.ContextService"] = function()

--[[
	ContextService.lua
	Gives the AI project-wide understanding: selection details, script sources,
	and a summarized hierarchy of the important services. Kept bounded for perf.
]]
local Selection = game:GetService("Selection")
local Config = _R("Config")

local ContextService = {}
ContextService.__index = ContextService

local INSPECTED_SERVICES = {
	"Workspace",
	"ServerScriptService",
	"ServerStorage",
	"ReplicatedStorage",
	"StarterGui",
	"StarterPlayer",
	"StarterPack",
	"Lighting",
}

-- Tree walks over big places are the single most expensive thing Bloxsmith
-- does per-request. Cache the result for a short window and reuse it across
-- consecutive messages instead of re-walking the whole DataModel every time —
-- this is the biggest lever on perceived "generation speed" for agent /
-- generate modes on large places.
local TREE_CACHE_TTL = 12 -- seconds

function ContextService.new()
	return setmetatable({ _treeCache = nil, _treeCacheAt = 0 }, ContextService)
end

local function fullName(inst)
	return inst:GetFullName()
end

-- Summarize a single instance for the AI (compact).
local function describe(inst)
	local info = { name = inst.Name, class = inst.ClassName, path = fullName(inst) }
	if inst:IsA("LuaSourceContainer") then
		local ok, src = pcall(function()
			return inst.Source
		end)
		if ok then
			if #src > 6000 then
				info.source = string.sub(src, 1, 6000) .. "\n--[[ ...TRUNCATED: script is " .. #src .. " chars, only the first 6000 shown to the AI... ]]"
			else
				info.source = src
			end
		end
	elseif inst:IsA("BasePart") then
		info.size = tostring(inst.Size)
		info.anchored = inst.Anchored
	end
	return info
end

-- Details for whatever is selected in Studio right now.
function ContextService:getSelection()
	local sel = Selection:Get()
	local out = {}
	for _, inst in ipairs(sel) do
		table.insert(out, describe(inst))
		if #out >= (Config.MaxSelectionContext or 40) then
			break
		end
	end
	return out
end

-- First selected script instance (for fix/explain/optimize).
function ContextService:getSelectedScript()
	for _, inst in ipairs(Selection:Get()) do
		if inst:IsA("LuaSourceContainer") then
			return inst
		end
	end
	return nil
end

-- Bounded walk producing a lightweight tree + counts. Cached for
-- TREE_CACHE_TTL seconds so rapid back-to-back agent turns (the common case
-- while iterating on a build) reuse the same walk instead of paying the full
-- hierarchy-scan cost on every single message.
function ContextService:getProjectTree()
	local now = os.clock()
	if self._treeCache and (now - self._treeCacheAt) < TREE_CACHE_TTL then
		return self._treeCache
	end

	local budget = Config.MaxContextInstances
	local counts = { scripts = 0, parts = 0, guis = 0, remotes = 0, total = 0 }

	local function walk(inst, depth, localBudget)
		if localBudget <= 0 or depth > 4 then
			return nil, localBudget
		end
		local node = { name = inst.Name, class = inst.ClassName }
		local kids = inst:GetChildren()
		local childNodes = {}
		for _, child in ipairs(kids) do
			localBudget -= 1
			budget -= 1
			counts.total += 1
			if child:IsA("LuaSourceContainer") then
				counts.scripts += 1
			elseif child:IsA("BasePart") then
				counts.parts += 1
			elseif child:IsA("GuiObject") or child:IsA("ScreenGui") then
				counts.guis += 1
			elseif child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
				counts.remotes += 1
			end
			if localBudget <= 0 then
				break
			end
			local sub
			sub, localBudget = walk(child, depth + 1, localBudget)
			if sub then
				table.insert(childNodes, sub)
			end
		end
		if #childNodes > 0 then
			node.children = childNodes
		end
		return node, localBudget
	end

	local tree = {}
	-- Split the budget evenly across services up front so one big service
	-- (Workspace, on almost any real game) can't silently eat the entire
	-- walk and make every later service falsely look empty to the AI. Any
	-- unused share from an early, smaller service rolls forward to the rest.
	local perServiceBudget = math.max(1, math.floor(budget / #INSPECTED_SERVICES))
	for _, svcName in ipairs(INSPECTED_SERVICES) do
		local ok, svc = pcall(function()
			return game:GetService(svcName)
		end)
		if ok and svc then
			local thisBudget = math.min(perServiceBudget, math.max(budget, 0))
			local node, leftover = walk(svc, 0, thisBudget)
			-- Roll back whatever this service didn't use into the shared pool.
			if leftover and leftover > 0 then
				budget += leftover
			end
			table.insert(tree, node)
		end
	end
	local result = { tree = tree, counts = counts }
	self._treeCache = result
	self._treeCacheAt = now
	return result
end

-- Force the next getProjectTree() call to re-walk instead of using the
-- cache — called after Apply actions mutate the place, so the AI always
-- sees an up-to-date hierarchy right after a change.
function ContextService:invalidateTreeCache()
	self._treeCache = nil
end

-- Full context bundle for AI calls.
function ContextService:build(includeTree)
	local ctx = { selection = self:getSelection() }
	if includeTree then
		local proj = self:getProjectTree()
		ctx.counts = proj.counts
		ctx.hierarchy = proj.tree
	end
	return ctx
end

return ContextService
end

_modules["Services.ErrorMonitor"] = function()

--[[
	ErrorMonitor.lua
	Captures Studio output errors via LogService and keeps a rolling buffer so the
	UI can surface them and offer AI-powered fixes.
]]
local LogService = game:GetService("LogService")
local Signal = _R("Util.Signal")

local ErrorMonitor = {}
ErrorMonitor.__index = ErrorMonitor

local MAX = 50

function ErrorMonitor.new()
	local self = setmetatable({}, ErrorMonitor)
	self.errors = {}
	self.Changed = Signal.new()
	self._conn = nil
	return self
end

function ErrorMonitor:start()
	if self._conn then
		return
	end
	self._conn = LogService.MessageOut:Connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageError then
			table.insert(self.errors, 1, { message = message, time = os.time() })
			while #self.errors > MAX do
				table.remove(self.errors)
			end
			self.Changed:Fire(self.errors)
		end
	end)
end

function ErrorMonitor:stop()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
end

function ErrorMonitor:clear()
	self.errors = {}
	self.Changed:Fire(self.errors)
end

function ErrorMonitor:get()
	return self.errors
end

return ErrorMonitor
end

_modules["Services.HealthService"] = function()

--[[
	HealthService.lua
	Aggregates the local analyzers into 0-100 scores for the health dashboard.
	Scores are heuristic and meant to guide attention, not to be absolute.
]]
local HealthService = {}
HealthService.__index = HealthService

function HealthService.new(security, performance, cleanup)
	return setmetatable({
		security = security,
		performance = performance,
		cleanup = cleanup,
	}, HealthService)
end

local WEIGHT = { Critical = 25, High = 15, Medium = 7, Low = 3 }

local function scoreFrom(findings)
	local score = 100
	for _, f in ipairs(findings) do
		score -= (WEIGHT[f.severity] or 3)
	end
	return math.clamp(score, 0, 100)
end

function HealthService:compute()
	local sec = self.security:scan()
	local perf = self.performance:analyze()
	local clean = self.cleanup:scan()

	return {
		security = { score = scoreFrom(sec), findings = sec },
		performance = { score = scoreFrom(perf.findings), findings = perf.findings, metrics = perf.metrics },
		organization = { score = scoreFrom(clean), findings = clean },
	}
end

return HealthService
end

_modules["Services.PerformanceAnalyzer"] = function()

--[[
	PerformanceAnalyzer.lua
	Heuristics for lag sources: unthrottled loops, per-frame work, excessive
	instances, unanchored parts, and connection leaks. Returns findings + metrics.
]]
local Workspace = game:GetService("Workspace")

local PerformanceAnalyzer = {}
PerformanceAnalyzer.__index = PerformanceAnalyzer

function PerformanceAnalyzer.new()
	return setmetatable({}, PerformanceAnalyzer)
end

function PerformanceAnalyzer:analyze()
	local findings = {}
	local metrics = { parts = 0, unanchored = 0, unions = 0, meshes = 0, scripts = 0, instances = 0 }

	-- Single pass over the whole tree (this used to be two full
	-- game:GetDescendants() walks — merged into one for large places).
	for _, d in ipairs(game:GetDescendants()) do
		metrics.instances += 1
		if d:IsA("BasePart") then
			metrics.parts += 1
			if not d.Anchored and not d:FindFirstAncestorWhichIsA("Model") then
				metrics.unanchored += 1
			end
			if d:IsA("UnionOperation") then
				metrics.unions += 1
			elseif d:IsA("MeshPart") then
				metrics.meshes += 1
			end
		elseif d:IsA("LuaSourceContainer") then
			metrics.scripts += 1
			local ok, src = pcall(function()
				return d.Source
			end)
			if ok and src then
				if string.find(src, "while%s+true%s+do") and not string.find(src, "task%.wait") and not string.find(src, "RunService") then
					table.insert(findings, {
						severity = "High",
						title = "Unthrottled while-true loop",
						advice = "Add task.wait() or it will spike CPU and can freeze the client.",
						path = d:GetFullName(),
					})
				end
				if string.find(src, "Heartbeat:Connect") or string.find(src, "RenderStepped:Connect") then
					if string.find(src, ":FindFirstChild") or string.find(src, "Instance.new") then
						table.insert(findings, {
							severity = "Medium",
							title = "Heavy work every frame",
							advice = "Per-frame FindFirstChild/Instance.new allocates constantly. Cache references outside the loop.",
							path = d:GetFullName(),
						})
					end
				end
				if string.find(src, ":Connect") and not string.find(src, ":Disconnect") and not string.find(src, "Once") then
					table.insert(findings, {
						severity = "Low",
						title = "Possible connection leak",
						advice = "Connections are never disconnected — store & clean them up to avoid memory growth.",
						path = d:GetFullName(),
					})
				end
			end
		end
		if metrics.instances > 60000 then
			break
		end
	end

	if metrics.parts > 15000 then
		table.insert(findings, {
			severity = "High",
			title = ("High part count (%d)"):format(metrics.parts),
			advice = "Consider streaming (StreamingEnabled), merging meshes, or culling distant detail.",
		})
	end
	if metrics.unions > 2000 then
		table.insert(findings, {
			severity = "Medium",
			title = ("Many UnionOperations (%d)"):format(metrics.unions),
			advice = "Unions are costly to render. Convert static unions to MeshParts where possible.",
		})
	end

	return { findings = findings, metrics = metrics }
end

return PerformanceAnalyzer
end

_modules["Services.SecurityScanner"] = function()

--[[
	SecurityScanner.lua
	Static analysis that flags common Roblox exploit vectors & bad practices.
	Fast, local, and heuristic — complements the deeper AI security review.
]]
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local SecurityScanner = {}
SecurityScanner.__index = SecurityScanner

-- pattern, severity, title, advice
local RULES = {
	{ "loadstring%s*%(", "Critical", "loadstring usage", "loadstring enables arbitrary code execution — remove it or disable LoadStringEnabled." },
	{ "require%s*%(%s*%d+%s*%)", "High", "require by asset id", "Requiring by numeric asset id can load untrusted code. Require by reference instead." },
	{ "getfenv%s*%(", "Medium", "getfenv/setfenv", "Environment manipulation is fragile and often abused. Avoid it." },
	{ "setfenv%s*%(", "Medium", "getfenv/setfenv", "Environment manipulation is fragile and often abused. Avoid it." },
	{ "_G%s*%[", "Low", "_G global state", "Shared mutable globals cause hard-to-trace bugs. Use ModuleScripts." },
	{ "HttpService.-JSONDecode%s*%(", "Low", "external data parsing", "Validate/whitelist any external data before use." },
	{ "while%s+true%s+do", "Medium", "possible unyielding loop", "Ensure a task.wait() exists inside, or it will freeze the game/exploit CPU." },
}

function SecurityScanner.new()
	return setmetatable({}, SecurityScanner)
end

local function scanContainers()
	local roots = { ServerScriptService, ReplicatedStorage, StarterPlayer, StarterGui, Workspace }
	local scripts = {}
	for _, root in ipairs(roots) do
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				table.insert(scripts, d)
			end
		end
	end
	return scripts
end

function SecurityScanner:scan()
	local findings = {}
	local scripts = scanContainers()

	for _, s in ipairs(scripts) do
		local ok, src = pcall(function()
			return s.Source
		end)
		if ok and src then
			for _, rule in ipairs(RULES) do
			local matchStart = string.find(src, rule[1])
			if matchStart then
				local isSafe = false
				if rule[3] == "possible unyielding loop" then
					-- The old check was `string.find(src, "task%.wait")` against
					-- the WHOLE script — so a real, unwaited infinite loop would
					-- pass as "safe" just because some UNRELATED function
					-- elsewhere in the same file (e.g. a cooldown) happened to
					-- call task.wait(). A full block-depth parser is fragile
					-- against nested if/for/function blocks, so instead we
					-- check a generous local window after the loop opens
					-- (2000 chars — comfortably covers a real loop body without
					-- needing a full Lua parser) for any wait/yield call.
					local windowEnd = math.min(#src, matchStart + 2000)
					local body = src:sub(matchStart, windowEnd)
					isSafe = (string.find(body, "task%.wait") ~= nil)
						or (string.find(body, "task%.yield") ~= nil)
						or (string.find(body, "%f[%a]wait%f[%A]") ~= nil)
						or (string.find(body, "coroutine%.yield") ~= nil)
				end
				if not isSafe then
					table.insert(findings, {
						severity = rule[2],
						title = rule[3],
						advice = rule[4],
						path = s:GetFullName(),
					})
				end
			end
		end

			-- Client-side RemoteEvent handlers that touch leaderstats = trust-the-client smell.
			if s:IsA("Script") and string.find(src, "OnServerEvent") and not string.find(src, "typeof") and not string.find(src, "assert") then
				table.insert(findings, {
					severity = "Medium",
					title = "unvalidated RemoteEvent",
					advice = "OnServerEvent handler appears to skip type/range validation. Never trust client-sent values.",
					path = s:GetFullName(),
				})
			end
		end
	end

	return findings
end

return SecurityScanner
end

_modules["UI.App"] = function()

--[[
	App.lua
	The whole Bloxsmith interface: sidebar navigation, chat, tools, project
	analysis, health dashboard, error monitor and settings. Pure Instance-based
	UI (no external libs) built through the Create helper and themed via Theme.
]]
local Create = _R("UI.Create")
local Theme = _R("UI.Theme")
local Parser = _R("Util.Parser")
local Config = _R("Config")

local App = {}
App.__index = App

function App.new(deps)
	local self = setmetatable({}, App)
	self.deps = deps
	self.history = {} -- {role, content}
	self.mode = "chat"
	self.views = {}
	self.navButtons = {}
	self.busy = false
	return self
end

--========================================================================
-- Small UI primitives
--========================================================================
local C = Theme.Color

local function corner(radius)
	return Create("UICorner", { CornerRadius = radius or Theme.Radius })
end

local function pad(px)
	px = px or Theme.Pad
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	})
end

local function stroke(color)
	return Create("UIStroke", { Color = color or C.Border, Thickness = 1 })
end

local function button(text, props)
	props = props or {}
	local bg = props.BackgroundColor3 or C.Accent
	local btn = Create("TextButton", {
		Text = text,
		Font = Theme.FontBold,
		TextSize = props.TextSize or 13,
		TextColor3 = props.TextColor3 or C.Text,
		BackgroundColor3 = bg,
		AutoButtonColor = true,
		Size = props.Size or UDim2.new(1, 0, 0, 32),
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	}, { corner(UDim.new(0, 6)) })
	-- Premium blue → cyan gradient on primary (accent) buttons.
	if bg == C.Accent then
		Create("UIGradient", {
			Color = ColorSequence.new(C.Accent, C.Accent2),
			Rotation = 90,
			Parent = btn,
		})
	end
	return btn
end


function App:toast(message, kind)
	local color = C.Info
	if kind == "success" then
		color = C.Success
	elseif kind == "warning" then
		color = C.Warning
	elseif kind == "error" then
		color = C.Error
	end
	local frame = Create("TextLabel", {
		Text = message,
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = C.Bg,
		BackgroundColor3 = color,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.toastHolder,
	}, { corner(UDim.new(0, 6)), pad(8) })
	task.delay(4, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

--========================================================================
-- Chat rendering
--========================================================================
function App:addBubble(role, text)
	local isUser = role == "user"
	local holder = Create("Frame", {
		BackgroundColor3 = isUser and C.UserBubble or C.AiBubble,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Border) })

	Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})

	Create("TextLabel", {
		Text = isUser and "You" or "Bloxsmith",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = isUser and C.Accent2 or C.Accent,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 0,
		Parent = holder,
	})

	-- Pull the AI's thinking/plan into its own collapsible panel (assistant only).
	local workingText = text
	if not isUser then
		local thinking, cleaned = Parser.extractThinking(text)
		workingText = cleaned
		if thinking and thinking ~= "" then
			self:addThinkingPanel(holder, thinking, 1)
		end
		local _, cleanedActions = Parser.extractActions(workingText)
		workingText = cleanedActions
	end

	-- Render the reply with code blocks stripped into their own panels.
	local blocks = Parser.extractBlocks(workingText)
	local prose = string.gsub(workingText, "```[^\n]*\n([%s%S]-)```", "\n〔 code block below 〕\n")
	prose = prose:gsub("^%s+", ""):gsub("%s+$", "")

	if prose ~= "" then
		Create("TextLabel", {
			Text = Parser.toRichText(prose),
			RichText = true,
			Font = Theme.Font,
			TextSize = 13,
			TextColor3 = C.Text,
			BackgroundTransparency = 1,
			TextWrapped = true,
			LineHeight = 1.08,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2,
			Parent = holder,
		})
	end

	-- "Insert all" shortcut when the reply contains multiple files.
	if #blocks > 1 then
		local insertAll = button(("＋ Insert all %d files into Studio"):format(#blocks), {
			LayoutOrder = 3,
			BackgroundColor3 = C.Success,
			TextColor3 = C.Bg,
		})
		insertAll.Parent = holder
		insertAll.Activated:Connect(function()
			local actions = {}
			for i, block in ipairs(blocks) do
				table.insert(actions, Parser.blockToAction(block, i))
			end
			local res = self.deps.apply:applyActions(actions, "Bloxsmith insert files")
			if res.ok then
				self:toast(("Inserted %d files (Ctrl+Z to undo)"):format(res.applied or #actions), "success")
			else
				self:toast(("Inserted %d of %d — check output."):format(res.applied or 0, #actions), "warning")
			end
		end)
	end

	for i, block in ipairs(blocks) do
		self:addCodeBlock(holder, block, i + 10)
	end


	self.chatScroll.CanvasPosition = Vector2.new(0, 1e6)
	return holder
end

-- Collapsible "💭 Thinking" panel showing the AI's plan/reasoning.
function App:addThinkingPanel(parent, thinking, order)
	local panel = Create("Frame", {
		BackgroundColor3 = C.PanelAlt,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 1,
		Parent = parent,
	}, { corner(UDim.new(0, 6)), pad(8), stroke(C.Accent2) })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	local expanded = false
	local header = Create("TextButton", {
		Text = "💭 Thinking  ▸",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = C.Accent2,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 0,
		Parent = panel,
	})

	local body = Create("TextLabel", {
		Text = Parser.toRichText(thinking),
		RichText = true,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = C.TextDim,
		BackgroundTransparency = 1,
		TextWrapped = true,
		LineHeight = 1.08,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		LayoutOrder = 1,
		Parent = panel,
	})

	header.Activated:Connect(function()
		expanded = not expanded
		body.Visible = expanded
		header.Text = expanded and "💭 Thinking  ▾" or "💭 Thinking  ▸"
	end)
end

-- Live animated "thinking" indicator shown while a request is in flight.
function App:startThinking()
	local holder = Create("Frame", {
		BackgroundColor3 = C.AiBubble,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Accent2) })
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = holder })
	Create("TextLabel", {
		Text = "Bloxsmith", Font = Theme.FontBold, TextSize = 11, TextColor3 = C.Accent,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14), Parent = holder,
	})
	local status = Create("TextLabel", {
		Text = "💭 Thinking.", Font = Theme.Font, TextSize = 13, TextColor3 = C.TextDim,
		BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = holder,
	})

	-- Cancel button — lets the user abandon a long build. The network call can't
	-- be aborted mid-flight, so cancelling flags the handle so its result is
	-- discarded and the UI is freed immediately.
	local handle = { cancelled = false }
	local cancelBtn = button("✕ Cancel", { Size = UDim2.new(0, 78, 0, 22), BackgroundColor3 = C.Panel, TextSize = 11 })
	cancelBtn.Parent = holder

	self.chatScroll.CanvasPosition = Vector2.new(0, 1e6)

	local phases = {
		"💭 Understanding your request",
		"🧭 Planning the build",
		"🧩 Designing the structure",
		"⌨️ Writing Luau",
		"🔌 Wiring it all up",
		"✨ Polishing the result",
	}
	local running = true
	local startedAt = os.clock()
	task.spawn(function()
		local i, dots = 1, 1
		while running and holder.Parent do
			local secs = math.floor(os.clock() - startedAt)
			status.Text = phases[i] .. string.rep(".", dots) .. ("   ⏱ %ds"):format(secs)
			dots += 1
			if dots > 3 then
				dots = 1
				i = (i % #phases) + 1
			end
			task.wait(0.5)
		end
	end)

	handle.stop = function()
		running = false
		if holder and holder.Parent then
			holder:Destroy()
		end
	end

	cancelBtn.Activated:Connect(function()
		self:stopActiveBuild()
	end)


	return handle
end



function App:addCodeBlock(parent, block, order)
	local panel = Create("Frame", {
		BackgroundColor3 = C.Bg,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	}, { corner(UDim.new(0, 6)), pad(8), stroke(C.AccentDim) })

	Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panel,
	})

	Create("TextLabel", {
		Text = string.format("%s  •  %s", block.class or "Script", block.path or "insert location auto-detected"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = C.TextDim,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 0,
		Parent = panel,
	})

	Create("TextLabel", {
		Text = block.source,
		Font = Theme.FontMono,
		TextSize = 12,
		TextColor3 = C.Success,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
		Parent = panel,
	})

	local insert = button("＋ Insert into Studio", { LayoutOrder = 2, BackgroundColor3 = C.AccentDim })
	insert.Parent = panel
	insert.Activated:Connect(function()
		insert.Text = "Inserting…"
		local action = Parser.blockToAction(block, order)
		local res = self.deps.apply:applyActions({ action }, "Bloxsmith insert script")
		if res.ok and (res.applied or 0) > 0 then
			local where = action.path or "ServerScriptService"
			self:toast(("✓ Added '%s' to %s (open Explorer to see it). Ctrl+Z to undo."):format(action.name or "script", where), "success")
			insert.Text = "✓ Inserted into " .. where
		else
			self:toast("Insert failed: " .. (res.error or "unknown"), "error")
			insert.Text = "＋ Retry insert"
		end
	end)

	-- Always give an execute option for Lua/Luau script blocks.
	if not block.lang or block.lang == "lua" or block.lang == "luau" or block.lang == "" then
		local execute = button("⚡ Execute / Run Code", { LayoutOrder = 3, BackgroundColor3 = C.Accent })
		execute.Parent = panel
		execute.Activated:Connect(function()
			execute.Text = "Executing…"
			execute.Active = false
			task.spawn(function()
				local ChangeHistoryService = game:GetService("ChangeHistoryService")
				local recordId = ChangeHistoryService:TryBeginRecording("Bloxsmith execute code")
				
				local ok, err = pcall(function()
					local fn, loadErr = loadstring(block.source)
					if not fn then
						error(loadErr)
					end
					setfenv(fn, getfenv(0))
					fn()
				end)
				
				if recordId then
					ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
				end
				
				execute.Active = true
				if ok then
					self:toast("✓ Executed successfully. Ctrl+Z to undo.", "success")
					execute.Text = "⚡ Executed"
					if self._activeFixBtn then
						self._activeFixBtn:Destroy()
						self._activeFixBtn = nil
					end
				else
					self:toast("Execution failed: " .. tostring(err), "error")
					execute.Text = "⚡ Retry Execution"
					warn("[Bloxsmith Exec Error]:", err)

					if self._activeFixBtn then
						self._activeFixBtn:Destroy()
					end
					local fixBtn = button("🔧 Auto-Fix Exec Error with AI", { LayoutOrder = 4, BackgroundColor3 = C.Warning })
					fixBtn.Parent = panel
					self._activeFixBtn = fixBtn
					fixBtn.Activated:Connect(function()
						fixBtn.Text = "Diagnosing…"
						fixBtn.Active = false
						self:send("The script failed with execution error:\n" .. tostring(err) .. "\n\nOriginal Code:\n" .. block.source, "fix_script")
					end)
				end
			end)
		end)
	end
end

local function buildOptimizedMessages(history)
	local messages = {}
	local totalLen = 0
	for _, m in ipairs(history) do
		totalLen = totalLen + string.len(m.content or "")
	end

	-- If history is short, send it as-is.
	if totalLen <= 8000 then
		for _, m in ipairs(history) do
			table.insert(messages, { role = m.role, content = m.content })
		end
		return messages
	end

	-- If history is long, prune older messages' code blocks.
	for i, m in ipairs(history) do
		local content = m.content
		-- Prune code blocks from older messages (leaving the last two turns fully intact)
		if i < #history - 1 and type(content) == "string" then
			content = string.gsub(content, "```[^\n]*\n[%s%S]-```", "\n[code block omitted for speed]\n")
		end
		table.insert(messages, { role = m.role, content = content })
	end
	return messages
end

--========================================================================
-- Backend call
--========================================================================
function App:send(promptText, mode)
	if self.busy then
		self:toast("Please wait for the current task to finish.", "warning")
		return
	end
	if not promptText or promptText == "" then
		return
	end
	self.busy = true
	self:setSendButtonStop(true)

	-- Dismiss the onboarding card on first message.
	if self._welcomeCard then
		self._welcomeCard:Destroy()
		self._welcomeCard = nil
	end

	self:addBubble("user", promptText)
	table.insert(self.history, { role = "user", content = promptText })

	-- Show the live thinking indicator immediately — don't make the user
	-- wait on a (possibly cold) hierarchy walk before they get feedback that
	-- something is happening. Context building + message optimization now
	-- happen inside the background task below, off the UI thread.
	local thinkingHandle = self:startThinking()
	self._activeThinking = thinkingHandle

	local includeTree = (mode == "agent" or mode == "generate_system" or mode == "generate_ui" or mode == "brainstorm")

	task.spawn(function()
		local context = self.deps.context:build(includeTree)
		local optimizedMessages = buildOptimizedMessages(self.history)
		local result = self.deps.ai:request({
			mode = mode or self.mode,
			messages = optimizedMessages,
			context = context,
		})
		-- If the user cancelled/stopped while the request was in flight, discard
		-- the result entirely — the UI was already freed by the stop handler.
		if thinkingHandle.cancelled then
			return
		end
		thinkingHandle.stop()
		self._activeThinking = nil
		self.busy = false
		self:setSendButtonStop(false)

		if result.ok then
			local reply = result.reply
			local actions, cleanedReply, foundBlock = Parser.extractActions(reply)
			if foundBlock then
				reply = cleanedReply
			end
			if not actions then
				actions = result.actions
			end
			if type(reply) ~= "string" or reply == "" then
				reply = "I prepared changes for your game. Review and approve them below."
			end
			self:addBubble("assistant", reply)
			table.insert(self.history, { role = "assistant", content = reply })
			if actions then
				self:proposeAgentActions(actions)
			end
		else
			local bubble = self:addBubble("assistant", "⚠️ " .. (result.error or "Request failed."))

			if type(result.resetAt) == "number" and result.resetAt > 0 then
				-- Rate-limited with a known reset time: show a live countdown
				-- instead of a Retry button that can't succeed until reset.
				local countdownLabel = Create("TextLabel", {
					Text = "⏳ Calculating…",
					Font = Theme.FontBold,
					TextSize = 12,
					TextColor3 = C.Warning,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, 0, 0, 18),
					LayoutOrder = 100,
					Parent = bubble,
				})

				local resetAtSeconds = result.resetAt / 1000 -- backend sends epoch ms
				local tickConn
				local function formatRemaining(secs)
					if secs <= 0 then return nil end
					local h = math.floor(secs / 3600)
					local m = math.floor((secs % 3600) / 60)
					local s = math.floor(secs % 60)
					if h > 0 then
						return ("⏳ Resets in %dh %dm %ds"):format(h, m, s)
					elseif m > 0 then
						return ("⏳ Resets in %dm %ds"):format(m, s)
					else
						return ("⏳ Resets in %ds"):format(s)
					end
				end

				local function updateCountdown()
					if not countdownLabel or not countdownLabel.Parent then
						if tickConn then pcall(task.cancel, tickConn) end
						return
					end
					local remaining = resetAtSeconds - os.time()
					local text = formatRemaining(remaining)
					if not text then
						countdownLabel.Text = "✅ Quota reset — you can try again now."
						countdownLabel.TextColor3 = C.Success
						if tickConn then pcall(task.cancel, tickConn) end
						-- Swap in a real Retry button now that the wait is over.
						local retryBtn = button("🔁 Retry Request", { LayoutOrder = 101, BackgroundColor3 = C.Panel, Size = UDim2.new(0, 120, 0, 26) })
						retryBtn.Parent = bubble
						retryBtn.Activated:Connect(function()
							retryBtn:Destroy()
							local lastPromptText = ""
							if #self.history > 0 and self.history[#self.history].role == "user" then
								local last = table.remove(self.history)
								lastPromptText = last.content
							end
							if lastPromptText ~= "" then
								self:send(lastPromptText, mode)
							end
						end)
						return
					end
					countdownLabel.Text = text
				end

				updateCountdown()
				tickConn = task.spawn(function()
					while countdownLabel and countdownLabel.Parent do
						task.wait(1)
						updateCountdown()
					end
				end)
			else
				local retryBtn = button("🔁 Retry Request", { LayoutOrder = 100, BackgroundColor3 = C.Panel, Size = UDim2.new(0, 120, 0, 26) })
				retryBtn.Parent = bubble
				retryBtn.Activated:Connect(function()
					retryBtn:Destroy()
					local lastPromptText = ""
					if #self.history > 0 and self.history[#self.history].role == "user" then
						local last = table.remove(self.history)
						lastPromptText = last.content
					end
					if lastPromptText ~= "" then
						self:send(lastPromptText, mode)
					end
				end)
			end
			self:toast(result.error or "Request failed.", "error")
		end
		-- Persist the running conversation so Bloxsmith remembers it across
		-- plugin reloads / Studio restarts.
		self:saveActiveSession()
	end)
end

-- Toggle the Send button between its normal state and an in-flight "Stop" state.
function App:setSendButtonStop(isStopping)
	if not self.sendBtn then
		return
	end
	if isStopping then
		self.sendBtn.Text = "⛔ Stop"
	else
		self.sendBtn.Text = "Send"
	end
end

-- Stop the current in-flight build: discard its result and free the UI. Shared
-- by the Send/Stop button and the in-bubble Cancel button.
function App:stopActiveBuild()
	local handle = self._activeThinking
	if handle then
		handle.cancelled = true
		if handle.stop then
			handle.stop()
		end
		self._activeThinking = nil
	end
	self.busy = false
	self:setSendButtonStop(false)
	self:toast("Build stopped.", "warning")
end

-- Human-readable one-line summary of a single agent action, for the plan checklist.
local function describeAction(a)
	local kind = a.action or "change"
	local name = a.name or a.target or a.class or ""
	local map = {
		create_script = "Create script",
		replace_script = "Replace script",
		create_folder = "Create folder",
		create_instance = "Create " .. tostring(a.class or "instance"),
		set_property = "Set " .. tostring(a.property or "property"),
		rename_instance = "Rename",
		delete_instance = "Delete",
		move_instance = "Move",
		insert_asset = "Insert asset",
	}
	local label = map[kind] or tostring(kind)
	if name ~= "" then
		label = label .. "  ·  " .. tostring(name)
	end
	if #label > 60 then
		label = label:sub(1, 57) .. "…"
	end
	return label
end

function App:proposeAgentActions(actions)
	if type(actions) ~= "table" or #actions == 0 then
		return
	end
	local holder = Create("Frame", {
		BackgroundColor3 = C.PanelAlt,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Accent) })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	Create("TextLabel", {
		Text = ("🤖 Build plan — %d step(s). Approve to apply:"):format(#actions),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = C.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 0,
		Parent = holder,
	})

	-- Live checklist: one row per action, ticked off as the build applies.
	local rows = {}
	for i, a in ipairs(actions) do
		rows[i] = Create("TextLabel", {
			Text = ("☐  %d. %s"):format(i, describeAction(a)),
			Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim,
			BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = i, Parent = holder,
		})
	end

	local approve = button("✓ Approve & Apply", { BackgroundColor3 = C.Success, TextColor3 = C.Bg, LayoutOrder = #actions + 1 })
	approve.Parent = holder
	approve.Activated:Connect(function()
		approve.Text = "Applying…"
		approve.Active = false
		local res = self.deps.apply:applyActions(actions, "Bloxsmith agent task")
		local results = res.results or {}
		for i, row in ipairs(rows) do
			local r = results[i]
			if r and r.ok then
				row.Text = ("✅  %d. %s"):format(i, describeAction(actions[i]))
				row.TextColor3 = C.Success
			elseif r then
				row.Text = ("❌  %d. %s"):format(i, describeAction(actions[i]))
				row.TextColor3 = C.Error
			end
		end
		if res.ok then
			self:toast(("Applied %d step(s). Ctrl+Z to undo."):format(#(res.created or {})), "success")
			approve.Text = "✓ Applied"
		else
			self:toast(("Applied %d of %d — check output."):format(res.applied or 0, #actions), "warning")
			approve.Text = "Applied with issues"
		end
		-- Auto-fix loop: if the build produced runtime errors, offer a one-tap fix.
		self:offerAutoFix()
	end)
end

-- If a runtime error appeared right after a build, surface a one-tap AI fix.
function App:offerAutoFix()
	local errs = self.deps.errors and self.deps.errors:get()
	if type(errs) ~= "table" or #errs == 0 then
		return
	end
	local latest = errs[1]
	if not latest or (os.time() - (latest.time or 0)) > 20 then
		return
	end
	local holder = Create("Frame", {
		BackgroundColor3 = C.PanelAlt, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Error) })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = holder })
	Create("TextLabel", {
		Text = "⚠️ An error appeared in Output. Want me to fix it?",
		Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Warning, BackgroundTransparency = 1,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), Parent = holder,
	})
	local fix = button("🔧 Fix this error with AI", { BackgroundColor3 = C.AccentDim })
	fix.Parent = holder
	fix.Activated:Connect(function()
		fix.Active = false
		fix.Text = "Fixing…"
		self:send("This error appeared after the last build. Diagnose the cause and fix it:\n" .. tostring(latest.message), "fix_script")
	end)
end

-- Quick-action helper: send the most recent captured error to the AI to fix.
function App:fixLatestError()
	local errs = self.deps.errors and self.deps.errors:get()
	if type(errs) ~= "table" or #errs == 0 then
		self:toast("No errors captured yet. Run your game to reproduce one.", "info")
		return
	end
	self:send("Fix this Roblox error — explain the cause and apply a fix:\n" .. tostring(errs[1].message), "fix_script")
end

--========================================================================
-- Views
--========================================================================
function App:buildChatView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = view })
	pad(0).Parent = view

	-- Header row: Clear + History
	local headerRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 0, Parent = view })
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = headerRow,
	})
	local historyBtn = button("🕘 History", { Size = UDim2.new(0, 92, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	historyBtn.Parent = headerRow
	historyBtn.Activated:Connect(function()
		self:toggleHistoryPanel(true)
	end)
	local clearBtn = button("🗑 Clear", { Size = UDim2.new(0, 80, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	clearBtn.Parent = headerRow
	clearBtn.Activated:Connect(function()
		self:clearChat()
	end)

	-- Selection context strip
	self.contextLabel = Create("TextLabel", {
		Text = "No selection",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = C.TextDim,
		BackgroundColor3 = C.Panel,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 1,
		Parent = view,
	}, { corner(UDim.new(0, 6)), pad(6) })

	-- Selection-aware quick edits — instant, undoable tweaks to whatever is
	-- selected in Studio (no AI round-trip needed).
	local selRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2, Parent = view })
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = selRow,
	})
	local selEdits = {
		{ "➕ Bigger", "scale", 1.25 },
		{ "➖ Smaller", "scale", 0.8 },
		{ "⧉ Duplicate", "duplicate" },
		{ "⚓ Anchor", "anchor", true },
		{ "🗑 Delete", "delete" },
	}
	for _, e in ipairs(selEdits) do
		local chip = button(e[1], { Size = UDim2.new(0, 78, 1, 0), BackgroundColor3 = C.Panel, TextSize = 11 })
		chip.Parent = selRow
		chip.Activated:Connect(function()
			local res = self.deps.apply:editSelection(e[2], e[3])
			if res.ok then
				self:toast(("Edited %d object(s). Ctrl+Z to undo."):format(res.count or 1), "success")
				self:refreshSelectionStrip()
			else
				self:toast(res.error or "Selection edit failed.", "warning")
			end
		end)
	end

	-- Persistent prompt quick-actions — one-tap common builds + auto-fix.
	local quickRow = Create("ScrollingFrame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26),
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
		ScrollingDirection = Enum.ScrollingDirection.X, BorderSizePixel = 0,
		LayoutOrder = 3, Parent = view,
	})
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = quickRow })
	local quickActions = {
		{ "🔧 Fix latest error", "__fix__" },
		{ "🏛 Build a lobby", "Build a polished game lobby with a spawn area, decorated environment and a play button UI.", "generate_system" },
		{ "🏆 Leaderboard", "Add a global leaderboard using OrderedDataStore that tracks player wins.", "generate_system" },
		{ "🌗 Day-night cycle", "Add a smooth continuous day-night cycle that animates Lighting.ClockTime.", "generate_system" },
		{ "🚪 Teleport pads", "Create two linked teleport pads that move the player between them on touch.", "generate_system" },
		{ "💰 Coin pickups", "Add collectable coins that give the player points and respawn after a short delay.", "generate_system" },
	}
	for i, qa in ipairs(quickActions) do
		local chip = button(qa[1], { Size = UDim2.new(0, 128, 1, 0), BackgroundColor3 = C.PanelAlt, TextSize = 11 })
		chip.LayoutOrder = i
		chip.Parent = quickRow
		chip.Activated:Connect(function()
			if qa[2] == "__fix__" then
				self:fixLatestError()
			else
				self:send(qa[2], qa[3])
			end
		end)
	end

	-- Chat scroll
	self.chatScroll = Create("ScrollingFrame", {
		BackgroundColor3 = C.BgAlt,
		Size = UDim2.new(1, 0, 1, -242),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.Accent,
		BorderSizePixel = 0,
		LayoutOrder = 4,
		Parent = view,
	}, { corner(UDim.new(0, 6)), pad(8) })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.chatScroll })

	-- Mode buttons row
	local modeRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 5, Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = modeRow })
	local modes = {
		{ "Chat", "chat" },
		{ "Generate", "agent" },
		{ "Script", "generate_script" },
		{ "Fix", "fix_script" },
		{ "Explain", "explain_script" },
		{ "Optimize", "optimize_script" }
	}
	self.modeButtons = {}
	for _, m in ipairs(modes) do
		local b = button(m[1], { Size = UDim2.new(1 / #modes, -4, 1, 0), BackgroundColor3 = C.Panel, TextSize = 10 })
		b.Parent = modeRow
		b.Activated:Connect(function()
			self:setMode(m[2])
		end)
		self.modeButtons[m[2]] = b
	end

	-- Input row
	local inputRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64), LayoutOrder = 6, Parent = view })
	self.input = Create("TextBox", {
		PlaceholderText = "Ask Bloxsmith or describe what to build…",
		Text = "",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = C.Text,
		PlaceholderColor3 = C.TextFaint,
		BackgroundColor3 = C.Panel,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = true,
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = inputRow,
	}, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })

	self.sendBtn = button("Send", { Size = UDim2.new(0, 62, 1, 0) })
	self.sendBtn.Position = UDim2.new(1, -62, 0, 0)
	self.sendBtn.Parent = inputRow
	self.sendBtn.Activated:Connect(function()
		-- While a build is in flight the Send button acts as a Stop button.
		if self.busy then
			self:stopActiveBuild()
			return
		end
		local text = self.input.Text
		self.input.Text = ""
		self:send(text, self.mode)
	end)

	self.chatView = view
	self:buildHistoryPanel(parent)
	self:setMode("chat")
	self:showWelcome()
end

--========================================================================
-- Chat history (persisted via plugin settings) + clear
--========================================================================
local HISTORY_KEY = "Bloxsmith_ChatHistory"
local ACTIVE_KEY = "Bloxsmith_ActiveSession"

function App:loadHistoryStore()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(HISTORY_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end

function App:saveHistoryStore(list)
	pcall(function()
		self.deps.plugin:SetSetting(HISTORY_KEY, list)
	end)
end

-- Persist the *current* conversation so Bloxsmith remembers context between
-- plugin reloads and Studio restarts (long-term memory).
function App:saveActiveSession()
	pcall(function()
		local snapshot = {}
		for _, m in ipairs(self.history or {}) do
			table.insert(snapshot, { role = m.role, content = m.content })
		end
		self.deps.plugin:SetSetting(ACTIVE_KEY, snapshot)
	end)
end

-- Restore the last active conversation on startup so the AI keeps its memory.
function App:restoreActiveSession()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(ACTIVE_KEY)
	end)
	if not (ok and type(data) == "table" and #data > 0) then
		return false
	end
	self.history = {}
	for _, m in ipairs(data) do
		if type(m) == "table" and m.role and m.content then
			table.insert(self.history, { role = m.role, content = m.content })
		end
	end
	if #self.history == 0 then
		return false
	end
	if self._welcomeCard then
		self._welcomeCard:Destroy()
		self._welcomeCard = nil
	end
	self:clearChatBubbles()
	for _, m in ipairs(self.history) do
		self:addBubble(m.role, m.content)
	end
	return true
end


-- Save the current conversation into persistent history (deduped, capped).
function App:saveCurrentConversation()
	if not self.history or #self.history == 0 then
		return
	end
	local list = self:loadHistoryStore()

	local title = "Conversation"
	for _, m in ipairs(self.history) do
		if m.role == "user" and m.content ~= "" then
			title = m.content
			break
		end
	end
	if #title > 60 then
		title = title:sub(1, 57) .. "…"
	end

	-- Skip if identical to the most recent saved conversation.
	local top = list[1]
	if top and top.messages and #top.messages == #self.history then
		local a = top.messages[#top.messages]
		local b = self.history[#self.history]
		if a and b and a.content == b.content then
			return
		end
	end

	local snapshot = {}
	for _, m in ipairs(self.history) do
		table.insert(snapshot, { role = m.role, content = m.content })
	end

	table.insert(list, 1, { title = title, time = os.time(), messages = snapshot })
	while #list > 25 do
		table.remove(list)
	end
	self:saveHistoryStore(list)
end

function App:clearChatBubbles()
	for _, ch in ipairs(self.chatScroll:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
			ch:Destroy()
		end
	end
	self._welcomeCard = nil
end

-- Clear button: archive the current chat, then reset to a fresh conversation.
function App:clearChat()
	if self.busy then
		self:toast("Please wait for the current task to finish.", "warning")
		return
	end
	self:saveCurrentConversation()
	self.history = {}
	self:saveActiveSession()
	self:clearChatBubbles()
	self:showWelcome()
	self:toast("Chat cleared — saved to History.", "success")
end

function App:loadConversation(convo)
	self.history = {}
	for _, m in ipairs(convo.messages or {}) do
		table.insert(self.history, { role = m.role, content = m.content })
	end
	self:clearChatBubbles()
	for _, m in ipairs(self.history) do
		self:addBubble(m.role, m.content)
	end
	self:saveActiveSession()
	self:toggleHistoryPanel(false)
	self:toast("Conversation loaded.", "success")
end

function App:toggleHistoryPanel(show)
	if not self.historyPanel then
		return
	end
	if show == nil then
		show = not self.historyPanel.Visible
	end
	if show then
		self:saveCurrentConversation()
		self:refreshHistoryPanel()
	end
	self.historyPanel.Visible = show
	if self.chatView then
		self.chatView.Visible = not show
	end
end

function App:buildHistoryPanel(parent)
	local panel = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	pad(0).Parent = panel
	self.historyPanel = panel

	-- Top bar
	local top = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 0, Parent = panel })
	local back = button("← Back", { Size = UDim2.new(0, 76, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	back.Parent = top
	back.Activated:Connect(function()
		self:toggleHistoryPanel(false)
	end)
	Create("TextLabel", {
		Text = "🕘 Chat History", Font = Theme.FontBold, TextSize = 14, TextColor3 = C.Text,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 84, 0, 0), Size = UDim2.new(1, -170, 1, 0), Parent = top,
	})
	local clearAll = button("Clear all", { Size = UDim2.new(0, 78, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	clearAll.Position = UDim2.new(1, -78, 0, 0)
	clearAll.Parent = top
	clearAll.Activated:Connect(function()
		self:saveHistoryStore({})
		self:refreshHistoryPanel()
		self:toast("History cleared.", "success")
	end)

	-- Scrollable list of saved conversations
	self.historyList = Create("ScrollingFrame", {
		BackgroundColor3 = C.BgAlt, Size = UDim2.new(1, 0, 1, -38),
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0,
		LayoutOrder = 1, Parent = panel,
	}, { corner(UDim.new(0, 6)), pad(8) })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.historyList })
end

function App:refreshHistoryPanel()
	if not self.historyList then
		return
	end
	for _, ch in ipairs(self.historyList:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
			ch:Destroy()
		end
	end

	local list = self:loadHistoryStore()
	if #list == 0 then
		Create("TextLabel", {
			Text = "No saved conversations yet.\nCleared chats are saved here automatically.",
			Font = Theme.Font, TextSize = 13, TextColor3 = C.TextDim, BackgroundTransparency = 1,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 60), Parent = self.historyList,
		})
		return
	end

	for i, convo in ipairs(list) do
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 54), LayoutOrder = i, Parent = self.historyList }, { corner(UDim.new(0, 6)), stroke(C.Border) })

		local openBtn = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, 0), Parent = card })
		Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), Parent = openBtn })
		Create("TextLabel", {
			Text = convo.title or "Conversation", Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, 0, 0, 18), Parent = openBtn,
		})
		local meta = ("%s · %d messages"):format(os.date("%b %d, %H:%M", convo.time or 0), #(convo.messages or {}))
		Create("TextLabel", {
			Text = meta, Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 14), Parent = openBtn,
		})
		openBtn.Activated:Connect(function()
			self:loadConversation(convo)
		end)

		local del = button("✕", { Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = C.PanelAlt, TextSize = 13 })
		del.Position = UDim2.new(1, -30, 0.5, -13)
		del.Parent = card
		del.Activated:Connect(function()
			local store = self:loadHistoryStore()
			table.remove(store, i)
			self:saveHistoryStore(store)
			self:refreshHistoryPanel()
		end)
	end
end


-- Friendly onboarding card with one-click starter prompts (empty chat only).
function App:showWelcome()
	if not self.chatScroll then
		return
	end
	local card = Create("Frame", {
		BackgroundColor3 = C.Panel,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.AccentDim) })
	self._welcomeCard = card
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	Create("TextLabel", {
		Text = "🔨 Welcome to Bloxsmith",
		Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = card,
	})
	Create("TextLabel", {
		Text = "Your AI copilot for Roblox. Describe what you want to build, or try one of these:",
		Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim,
		BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1, Parent = card,
	})

	local starters = {
		{ "🎒 Build an inventory system", "Build a complete server-authoritative inventory system with a client UI.", "generate_system" },
		{ "🛒 Create a shop with 5 items", "Create a shop system with 5 purchasable items and a polished UI.", "generate_system" },
		{ "🏆 Add a global leaderboard", "Add a global leaderboard using OrderedDataStore that tracks player wins.", "generate_system" },
		{ "⚔️ Combat system with weapons", "Build a server-authoritative melee combat system with a sword tool.", "generate_system" },
		{ "🚪 Explain the selected script", "Explain what the selected script does and how it works.", "explain_script" },
	}
	for i, s in ipairs(starters) do
		local chip = button(s[1], { LayoutOrder = i + 1, BackgroundColor3 = C.PanelAlt, TextSize = 12 })
		chip.Parent = card
		chip.Activated:Connect(function()
			self:send(s[2], s[3])
		end)
	end
end

function App:setMode(mode)
	self.mode = mode
	for m, b in pairs(self.modeButtons or {}) do
		b.BackgroundColor3 = (m == mode) and C.Accent or C.Panel
	end
end


-- Generic results list used by Analysis / Health.
function App:renderFindings(parent, findings, emptyMsg)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Frame") and child:GetAttribute("finding") then
			child:Destroy()
		end
	end
	if #findings == 0 then
		local ok = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent }, { corner(UDim.new(0, 6)), pad(8) })
		ok:SetAttribute("finding", true)
		Create("TextLabel", { Text = "✓ " .. (emptyMsg or "Nothing found. Looking good!"), Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Success, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = ok })
		return
	end
	for _, f in ipairs(findings) do
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent }, { corner(UDim.new(0, 6)), pad(8) })
		card:SetAttribute("finding", true)
		Create("UIListLayout", { Padding = UDim.new(0, 3), Parent = card })
		Create("UIStroke", { Color = Theme.severityColor(f.severity), Thickness = 1, Parent = card })
		Create("TextLabel", { Text = string.format("[%s] %s", string.upper(f.severity or "INFO"), f.title or ""), Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.severityColor(f.severity), BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
		if f.path then
			Create("TextLabel", { Text = f.path, Font = Theme.FontMono, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
		end
		Create("TextLabel", { Text = f.advice or "", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
	end
end

function App:buildAnalysisView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	local row = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = row })
	local sec = button("🛡 Security", { Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = C.Panel })
	local perf = button("⚡ Performance", { Size = UDim2.new(0, 110, 1, 0), BackgroundColor3 = C.Panel })
	local clean = button("🧹 Cleanup", { Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = C.Panel })
	sec.Parent, perf.Parent, clean.Parent = row, row, row

	local results = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = results })

	-- Runs a scan off the UI thread so a large place doesn't visibly freeze
	-- Studio when the button is clicked, and disables the button meanwhile
	-- so double-clicks don't queue up overlapping scans.
	local function runScan(btn, label, fn)
		local scanning = false
		btn.Activated:Connect(function()
			if scanning then return end
			scanning = true
			local original = btn.Text
			btn.Text = "Scanning…"
			btn.Active = false
			task.spawn(function()
				local ok, err = pcall(fn)
				btn.Text = original
				btn.Active = true
				scanning = false
				if not ok then
					self:toast("Scan failed: " .. tostring(err), "error")
				end
			end)
		end)
	end

	runScan(sec, "security", function()
		self:renderFindings(results, self.deps.security:scan(), "No security issues detected.")
		self:toast("Security scan complete.", "success")
	end)
	runScan(perf, "performance", function()
		local r = self.deps.performance:analyze()
		self:renderFindings(results, r.findings, "No performance issues detected.")
		self:toast(("Perf: %d parts, %d scripts, %d unions."):format(r.metrics.parts, r.metrics.scripts, r.metrics.unions), "info")
	end)
	runScan(clean, "cleanup", function()
		self:renderFindings(results, self.deps.cleanup:scan(), "Project is tidy!")
		self:toast("Cleanup scan complete.", "success")
	end)
end

function App:buildHealthView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	local scoresRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 70), Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = scoresRow })

	local function scoreCard(title)
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(0.33, -4, 1, 0), Parent = scoresRow }, { corner(UDim.new(0, 8)), pad(6) })
		Create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), Parent = card })
		local num = Create("TextLabel", { Text = "–", Font = Theme.FontBold, TextSize = 26, TextColor3 = C.TextDim, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = card })
		Create("TextLabel", { Text = title, Font = Theme.Font, TextSize = 11, TextColor3 = C.TextDim, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Parent = card })
		return num
	end
	local secNum = scoreCard("Security")
	local perfNum = scoreCard("Performance")
	local orgNum = scoreCard("Organization")

	local computeBtn = button("Compute health scores", { Size = UDim2.new(1, 0, 0, 32) })
	computeBtn.Parent = view
	local recBtn = button("✨ Get AI recommendations", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.Accent2 })
	recBtn.Parent = view

	local results = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = results })

	local computing = false
	computeBtn.Activated:Connect(function()
		if computing then return end
		computing = true
		local original = computeBtn.Text
		computeBtn.Text = "Computing…"
		computeBtn.Active = false
		task.spawn(function()
			local ok, h = pcall(function()
				return self.deps.health:compute()
			end)
			computeBtn.Text = original
			computeBtn.Active = true
			computing = false
			if not ok then
				self:toast("Health compute failed: " .. tostring(h), "error")
				return
			end
			secNum.Text = tostring(h.security.score)
			secNum.TextColor3 = Theme.scoreColor(h.security.score)
			perfNum.Text = tostring(h.performance.score)
			perfNum.TextColor3 = Theme.scoreColor(h.performance.score)
			orgNum.Text = tostring(h.organization.score)
			orgNum.TextColor3 = Theme.scoreColor(h.organization.score)
			local all = {}
			for _, list in ipairs({ h.security.findings, h.performance.findings, h.organization.findings }) do
				for _, f in ipairs(list) do
					table.insert(all, f)
				end
			end
			self:renderFindings(results, all, "Excellent — no issues across the board!")
			self:toast("Health computed.", "success")
		end)
	end)

	recBtn.Activated:Connect(function()
		self:selectView("Chat")
		self:setMode("chat")
		self:send("Review my project and give prioritized recommendations for gameplay, monetization, retention and UX.", "recommend")
	end)
end

function App:buildErrorsView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	local row = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = row })
	local clearBtn = button("Clear", { Size = UDim2.new(0, 70, 1, 0), BackgroundColor3 = C.Panel })
	clearBtn.Parent = row

	local list = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -38), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = list })

	local function render()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		local errs = self.deps.errors:get()
		if #errs == 0 then
			Create("TextLabel", { Text = "No errors captured. Errors printed to Output will appear here.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundColor3 = C.Panel, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = list }, { corner(UDim.new(0, 6)), pad(8) }) })
			return
		end
		for _, e in ipairs(errs) do
			local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = list }, { corner(UDim.new(0, 6)), pad(8) })
			Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = card })
			Create("UIStroke", { Color = C.Error, Thickness = 1, Parent = card })
			Create("TextLabel", { Text = e.message, Font = Theme.FontMono, TextSize = 12, TextColor3 = C.Error, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
			local fix = button("🔧 Fix with AI", { Size = UDim2.new(0, 110, 0, 26), BackgroundColor3 = C.AccentDim, TextSize = 11 })
			fix.Parent = card
			fix.Activated:Connect(function()
				self:selectView("Chat")
				self:send("I got this Roblox error, explain the cause and how to fix it:\n" .. e.message, "chat")
			end)
		end
	end

	clearBtn.Activated:Connect(function()
		self.deps.errors:clear()
	end)
	self.deps.errors.Changed:Connect(function()
		if self.currentView == "Errors" then
			render()
		end
	end)
	self._renderErrors = render
end

function App:buildToolsView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = view })
	pad(0).Parent = view

	Create("TextLabel", { Text = "Quick actions — type a description, then run. Uses your current selection & project as context.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	local box = Create("TextBox", { PlaceholderText = "e.g. a wave-based zombie survival shop with 6 weapons", Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, MultiLine = true, TextWrapped = true, Size = UDim2.new(1, 0, 0, 72), Parent = view }, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })

	local tools = {
		{ "🎮 Generate game system", "generate_system", "Build a complete system for: " },
		{ "🖼 Generate UI", "generate_ui", "Create a polished UI for: " },
		{ "🤖 Run build agent", "agent", "Complete this task, propose actions to apply: " },
		{ "💡 Brainstorm ideas", "brainstorm", "Brainstorm gameplay loops, features, mechanics or design ideas for: " },
		{ "📄 Generate docs", "docs", "Write documentation for the selected script(s). Notes: " },
		{ "🛠 Fix selected script", "fix_script", "Fix the selected script. Notes: " },
		{ "⚡ Optimize selected script", "optimize_script", "Optimize the selected script. Notes: " },
	}
	for _, t in ipairs(tools) do
		local b = button(t[1], { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.Panel })
		b.Parent = view
		b.Activated:Connect(function()
			self:selectView("Chat")
			self:send(t[3] .. (box.Text ~= "" and box.Text or "(see selection)"), t[2])
			box.Text = ""
		end)
	end

	-- Prompt presets — save the current description and re-run it later.
	local savePreset = button("💾 Save prompt as preset", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.PanelAlt, TextSize = 12 })
	savePreset.Parent = view
	local presetHolder = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = presetHolder })
	local function refreshPresets()
		for _, c in ipairs(presetHolder:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		local presets = self:loadPromptPresets()
		if #presets == 0 then return end
		Create("TextLabel", { Text = "⭐ Saved presets (tap to load, ✕ to remove)", Font = Theme.FontBold, TextSize = 11, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0, Parent = presetHolder })
		for i, p in ipairs(presets) do
			local rowf = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, Parent = presetHolder }, { corner(UDim.new(0, 6)), stroke(C.Border) })
			local load = Create("TextButton", { Text = "  " .. p, Font = Theme.Font, TextSize = 12, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -32, 1, 0), Parent = rowf })
			load.Activated:Connect(function()
				box.Text = p
				self:toast("Preset loaded into the box.", "success")
			end)
			local del = button("✕", { Size = UDim2.new(0, 26, 0, 24), BackgroundColor3 = C.PanelAlt, TextSize = 12 })
			del.Position = UDim2.new(1, -28, 0.5, -12)
			del.Parent = rowf
			del.Activated:Connect(function()
				local list = self:loadPromptPresets()
				table.remove(list, i)
				self:savePromptPresets(list)
				refreshPresets()
			end)
		end
	end
	savePreset.Activated:Connect(function()
		local txt = (box.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if txt == "" then
			self:toast("Type a description first.", "warning")
			return
		end
		local list = self:loadPromptPresets()
		table.insert(list, 1, txt)
		while #list > 15 do
			table.remove(list)
		end
		self:savePromptPresets(list)
		refreshPresets()
		self:toast("Preset saved.", "success")
	end)
	refreshPresets()
end

-- Prompt presets storage (persisted via plugin settings).
local PROMPT_PRESETS_KEY = "Bloxsmith_PromptPresets"
function App:loadPromptPresets()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(PROMPT_PRESETS_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end
function App:savePromptPresets(list)
	pcall(function()
		self.deps.plugin:SetSetting(PROMPT_PRESETS_KEY, list)
	end)
end

--========================================================================
-- Toolbox (Creator Store free-model search + insert)
--========================================================================
function App:buildToolboxView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = view })
	pad(0).Parent = view

	Create("TextLabel", {
		Text = "🧰 Search the Roblox Toolbox for free models and insert them straight into your game.",
		Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 0, Parent = view,
	})

	-- Search row
	local searchRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1, Parent = view })
	local searchBox = Create("TextBox", {
		PlaceholderText = "Search models… e.g. medieval house, sports car, tree",
		Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint,
		BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		Size = UDim2.new(1, -74, 1, 0), Parent = searchRow,
	}, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local searchBtn = button("Search", { Size = UDim2.new(0, 66, 1, 0) })
	searchBtn.Position = UDim2.new(1, -66, 0, 0)
	searchBtn.Parent = searchRow

	-- Category filter chips — narrow searches to a kind of asset.
	local currentCategory = ""
	local categoryRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 2, Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = categoryRow })
	local categories = {
		{ "All", "" },
		{ "Models", "model" },
		{ "Vehicles", "vehicle" },
		{ "Buildings", "building" },
		{ "Nature", "tree nature" },
		{ "Weapons", "weapon" },
	}
	local catButtons = {}
	local function setCategory(value, btn)
		currentCategory = value
		for _, cb in ipairs(catButtons) do
			cb.BackgroundColor3 = (cb == btn) and C.Accent or C.Panel
		end
	end
	for _, c in ipairs(categories) do
		local cb = button(c[1], { Size = UDim2.new(0, 66, 1, 0), BackgroundColor3 = (c[2] == "") and C.Accent or C.Panel, TextSize = 11 })
		cb.Parent = categoryRow
		table.insert(catButtons, cb)
		cb.Activated:Connect(function()
			setCategory(c[2], cb)
		end)
	end

	-- Insert-by-ID row (reliable fallback)
	local idRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 3, Parent = view })
	local idBox = Create("TextBox", {
		PlaceholderText = "…or paste a model Asset ID", Text = "", Font = Theme.FontMono, TextSize = 12,
		TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint, BackgroundColor3 = C.Panel,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		Size = UDim2.new(1, -74, 1, 0), Parent = idRow,
	}, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local idBtn = button("Insert", { Size = UDim2.new(0, 66, 1, 0), BackgroundColor3 = C.Success, TextColor3 = C.Bg })
	idBtn.Position = UDim2.new(1, -66, 0, 0)
	idBtn.Parent = idRow

	-- Favorites + recently inserted strips — one-click re-insert of saved models.
	local recentsHolder = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = recentsHolder })

	-- Bulk insert row — drop every current search result at once.
	local lastResults = {}
	local bulkRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 5, Parent = view })
	local bulkBtn = button("＋ Insert all results", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.AccentDim, TextSize = 12 })
	bulkBtn.Visible = false
	bulkBtn.Parent = bulkRow
	local function updateBulk()
		if #lastResults > 0 then
			bulkRow.Size = UDim2.new(1, 0, 0, 28)
			bulkBtn.Visible = true
			bulkBtn.Text = ("＋ Insert all %d results"):format(#lastResults)
		else
			bulkRow.Size = UDim2.new(1, 0, 0, 0)
			bulkBtn.Visible = false
		end
	end

	-- Results scroll
	local results = Create("ScrollingFrame", {
		BackgroundColor3 = C.BgAlt, Size = UDim2.new(1, 0, 1, -190), CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent,
		BorderSizePixel = 0, LayoutOrder = 6, Parent = view,
	}, { corner(UDim.new(0, 6)), pad(8) })
	local grid = Create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, 202), CellPadding = UDim2.new(0, 8, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = results,
	})

	-- Render a horizontal chip strip of saved models (favorites / recents).
	local function makeStrip(title, items, order, removeFn)
		local wrap = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = recentsHolder })
		Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap })
		Create("TextLabel", {
			Text = title, Font = Theme.FontBold, TextSize = 11, TextColor3 = C.TextDim,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0, Parent = wrap,
		})
		local strip = Create("ScrollingFrame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
			ScrollingDirection = Enum.ScrollingDirection.X, BorderSizePixel = 0, LayoutOrder = 1, Parent = wrap,
		})
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = strip })
		for i, item in ipairs(items) do
			local chip = button("＋ " .. (item.name or ("Asset " .. tostring(item.id))), { Size = UDim2.new(0, 130, 1, 0), BackgroundColor3 = C.Panel, TextSize = 11 })
			chip.LayoutOrder = i
			chip.Parent = strip
			chip.Activated:Connect(function()
				chip.Text = "Inserting…"
				task.spawn(function()
					local res = self.deps.apply:insertAsset(item.id, item.name)
					if res.ok then
						self:toast(("Re-inserted '%s' — Ctrl+Z to undo."):format(item.name or "model"), "success")
						chip.Text = "✓ Inserted"
					else
						self:toast(res.error or "Insert failed.", "error")
						chip.Text = "＋ Retry"
					end
				end)
			end)
			if removeFn then
				local x = button("✕", { Size = UDim2.new(0, 22, 1, 0), BackgroundColor3 = C.PanelAlt, TextSize = 11 })
				x.LayoutOrder = i
				x.Parent = strip
				x.Activated:Connect(function()
					removeFn(item.id)
				end)
			end
		end
	end

	-- Render favorites first, then recently inserted, from persisted storage.
	local refreshRecents
	refreshRecents = function()
		for _, c in ipairs(recentsHolder:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		local favs = self:loadToolboxFavorites()
		if #favs > 0 then
			makeStrip("⭐ Favorites", favs, 0, function(id)
				self:removeToolboxFavorite(id)
				refreshRecents()
			end)
		end
		local recents = self:loadToolboxRecents()
		if #recents > 0 then
			makeStrip("🕘 Recently inserted", recents, 1)
		end
	end
	self._refreshToolboxRecents = refreshRecents
	refreshRecents()



	local function clearResults()
		for _, c in ipairs(results:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
	end

	local function status(msg, kind)
		clearResults()
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = results }, { corner(UDim.new(0, 6)), pad(10) })
		-- Make the status span the full width by clearing grid influence.
		Create("TextLabel", {
			Text = msg, Font = Theme.Font, TextSize = 12,
			TextColor3 = kind == "error" and C.Error or C.TextDim, BackgroundTransparency = 1,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0), Parent = card,
		})
	end

	local function renderResults(items)
		clearResults()
		lastResults = items or {}
		updateBulk()
		if #items == 0 then
			status("No models found. Try different keywords.")
			return
		end
		for i, item in ipairs(items) do
			local card = Create("Frame", { BackgroundColor3 = C.Panel, LayoutOrder = i, Parent = results }, { corner(UDim.new(0, 8)), pad(6), stroke(C.Border) })
			Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
			-- Use Roblox's native thumbnail endpoint so the REAL model image renders
			-- inside Studio. ImageLabel cannot load raw CDN https URLs, but rbxthumb:// is
			-- resolved natively by the engine from the asset id.
			local thumb = item.id and ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(item.id) or (item.thumbnail or "")
			local imgHolder = Create("Frame", {
				BackgroundColor3 = C.Bg, Size = UDim2.new(1, 0, 0, 78), LayoutOrder = 0, Parent = card,
			}, { corner(UDim.new(0, 6)) })
			Create("ImageLabel", {
				Image = thumb, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.new(1, 0, 1, 0), Parent = imgHolder,
			})

			Create("TextLabel", {
				Text = item.name or "Model", Font = Theme.FontBold, TextSize = 12, TextColor3 = C.Text,
				BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = card,
			})
			local insertBtn = button("＋ Insert", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.AccentDim, TextSize = 11, LayoutOrder = 2 })
			insertBtn.Parent = card
			insertBtn.Activated:Connect(function()
				insertBtn.Text = "Inserting…"
				task.spawn(function()
					local res = self.deps.apply:insertAsset(item.id, item.name)
					if res.ok then
						local msg = (res.results and res.results[1] and res.results[1].message)
							or ("Inserted '%s' (Ctrl+Z to undo)"):format(item.name or "model")
						self:toast(msg .. " — Ctrl+Z to undo", "success")
						insertBtn.Text = "✓ Inserted"
						self:addToolboxRecent(item.id, item.name)
						refreshRecents()
					else
						self:toast(res.error or "Insert failed.", "error")
						insertBtn.Text = "＋ Retry"
					end
				end)
			end)

			-- Favorite toggle — pin a model to the favorites strip for instant re-use.
			local favBtn = button(self:isToolboxFavorite(item.id) and "⭐ Favorited" or "☆ Favorite", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = C.Panel, TextSize = 10, LayoutOrder = 3 })
			favBtn.Parent = card
			favBtn.Activated:Connect(function()
				local nowFav = self:toggleToolboxFavorite(item.id, item.name)
				favBtn.Text = nowFav and "⭐ Favorited" or "☆ Favorite"
				refreshRecents()
			end)

			-- Asset ID row at the bottom (also copy-selectable via the search box).
			Create("TextLabel", {
				Text = "ID: " .. tostring(item.id or "?"), Font = Theme.FontMono, TextSize = 10,
				TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 4, Parent = card,
			})
		end
	end

	local function runSearch(query)
		query = query and query:gsub("^%s+", ""):gsub("%s+$", "") or ""
		-- Blend in the active category so filters narrow the results.
		local full = (currentCategory ~= "") and (currentCategory .. " " .. query) or query
		if full == "" then return end
		status("🔎 Searching the Toolbox…")
		task.spawn(function()
			local res = self.deps.ai:searchToolbox(full)
			if res.ok then
				renderResults(res.results or {})
			else
				status(res.error or "Search failed.", "error")
			end
		end)
	end

	searchBtn.Activated:Connect(function()
		runSearch(searchBox.Text)
	end)
	bulkBtn.Activated:Connect(function()
		if #lastResults == 0 then return end
		bulkBtn.Text = "Inserting…"
		bulkBtn.Active = false
		task.spawn(function()
			local ok, fail = 0, 0
			for _, item in ipairs(lastResults) do
				local res = self.deps.apply:insertAsset(item.id, item.name)
				if res.ok then
					ok += 1
					self:addToolboxRecent(item.id, item.name)
				else
					fail += 1
				end
				task.wait(0.15)
			end
			refreshRecents()
			self:toast(("Inserted %d model(s)%s. Ctrl+Z to undo."):format(ok, fail > 0 and (", " .. fail .. " failed") or ""), ok > 0 and "success" or "error")
			bulkBtn.Active = true
			updateBulk()
		end)
	end)
	searchBox.FocusLost:Connect(function(enter)
		if enter then runSearch(searchBox.Text) end
	end)
	idBtn.Activated:Connect(function()
		local id = tonumber(idBox.Text)
		if not id then
			self:toast("Enter a valid numeric Asset ID.", "warning")
			return
		end
		idBtn.Text = "…"
		task.spawn(function()
			local res = self.deps.apply:insertAsset(id)
			idBtn.Text = "Insert"
			if res.ok then
				local msg = (res.results and res.results[1] and res.results[1].message)
					or ("Inserted asset " .. id)
				self:toast(msg .. " — Ctrl+Z to undo", "success")
				idBox.Text = ""
				self:addToolboxRecent(id, "Asset " .. tostring(id))
				refreshRecents()
			else
				self:toast(res.error or "Insert failed.", "error")
			end
		end)
	end)
end

-- Toolbox recents — persisted list of {id, name} for one-click re-insert.
local TOOLBOX_RECENTS_KEY = "Bloxsmith_ToolboxRecents"

function App:loadToolboxRecents()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(TOOLBOX_RECENTS_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end

function App:addToolboxRecent(id, name)
	id = tonumber(id)
	if not id then
		return
	end
	local list = self:loadToolboxRecents()
	-- De-dupe: drop any existing entry with the same id, then prepend.
	for i = #list, 1, -1 do
		if tonumber(list[i].id) == id then
			table.remove(list, i)
		end
	end
	table.insert(list, 1, { id = id, name = name or ("Asset " .. tostring(id)) })
	while #list > 12 do
		table.remove(list)
	end
	pcall(function()
		self.deps.plugin:SetSetting(TOOLBOX_RECENTS_KEY, list)
	end)
end

-- Toolbox favorites — pinned {id, name} models for one-click re-insert.
local TOOLBOX_FAVORITES_KEY = "Bloxsmith_ToolboxFavorites"

function App:loadToolboxFavorites()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(TOOLBOX_FAVORITES_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end

function App:isToolboxFavorite(id)
	id = tonumber(id)
	if not id then
		return false
	end
	for _, item in ipairs(self:loadToolboxFavorites()) do
		if tonumber(item.id) == id then
			return true
		end
	end
	return false
end

function App:saveToolboxFavorites(list)
	pcall(function()
		self.deps.plugin:SetSetting(TOOLBOX_FAVORITES_KEY, list)
	end)
end

function App:removeToolboxFavorite(id)
	id = tonumber(id)
	if not id then
		return
	end
	local list = self:loadToolboxFavorites()
	for i = #list, 1, -1 do
		if tonumber(list[i].id) == id then
			table.remove(list, i)
		end
	end
	self:saveToolboxFavorites(list)
end

-- Toggle a model's favorite state; returns true if it is now a favorite.
function App:toggleToolboxFavorite(id, name)
	id = tonumber(id)
	if not id then
		return false
	end
	local list = self:loadToolboxFavorites()
	for i = #list, 1, -1 do
		if tonumber(list[i].id) == id then
			table.remove(list, i)
			self:saveToolboxFavorites(list)
			return false
		end
	end
	table.insert(list, 1, { id = id, name = name or ("Asset " .. tostring(id)) })
	while #list > 20 do
		table.remove(list)
	end
	self:saveToolboxFavorites(list)
	return true
end




-- A labelled control that cycles through a list of options on click and
-- persists the chosen value to a plugin setting.
function App:cyclePref(parent, label, settingKey, options, default)
	Create("TextLabel", { Text = label, Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Parent = parent })
	local current = self.deps.ai.plugin:GetSetting(settingKey) or default
	local idx = 1
	for i, opt in ipairs(options) do
		if opt == current then idx = i break end
	end
	local btn = button("◀   " .. current .. "   ▶", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.Panel, TextColor3 = C.Text })
	stroke(C.Border).Parent = btn
	btn.Parent = parent
	local function set(newIdx)
		idx = ((newIdx - 1) % #options) + 1
		btn.Text = "◀   " .. options[idx] .. "   ▶"
		self.deps.ai.plugin:SetSetting(settingKey, options[idx])
	end
	btn.Activated:Connect(function()
		set(idx + 1)
		self:toast(label .. ": " .. options[idx], "success")
	end)
end

function App:buildSettingsView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = C.Border, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	-- Customization
	Create("TextLabel", { Text = "🎨 Customization", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = view })

	self:cyclePref(view, "AI personality", Config.Settings.Persona, Config.Personas, Config.Defaults.Persona)
	self:cyclePref(view, "Response length", Config.Settings.ResponseLength, Config.ResponseLengths, Config.Defaults.ResponseLength)

	Create("TextLabel", { Text = "Custom instructions", Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Parent = view })
	local ci = self.deps.ai.plugin:GetSetting(Config.Settings.CustomInstructions) or ""
	local ciBox = Create("TextBox", { PlaceholderText = "e.g. Always use OOP modules. Comment every function. Prefer Knit framework.", Text = ci, Font = Theme.Font, TextSize = 12, TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, MultiLine = true, TextWrapped = true, Size = UDim2.new(1, 0, 0, 70), Parent = view }, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local ciSave = button("Save custom instructions", { Size = UDim2.new(1, 0, 0, 30) })
	ciSave.Parent = view
	ciSave.Activated:Connect(function()
		local txt = string.sub(ciBox.Text or "", 1, Config.MaxCustomInstructions)
		self.deps.ai.plugin:SetSetting(Config.Settings.CustomInstructions, txt)
		self:toast("Custom instructions saved.", "success")
	end)

	Create("TextLabel", { Text = "Personality, length and custom instructions shape every AI reply and are sent securely with each request.", Font = Theme.Font, TextSize = 11, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	-- Connection
	Create("TextLabel", { Text = "🔌 Connection", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = view })

	Create("TextLabel", { Text = "Backend URL", Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Parent = view })
	local urlBox = Create("TextBox", { Text = self.deps.ai:getUrl(), Font = Theme.FontMono, TextSize = 12, TextColor3 = C.Text, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextWrapped = true, Size = UDim2.new(1, 0, 0, 50), Parent = view }, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local save = button("Save backend URL", { Size = UDim2.new(1, 0, 0, 32) })
	save.Parent = view
	save.Activated:Connect(function()
		self.deps.ai:setUrl(urlBox.Text)
		self:toast("Backend URL saved.", "success")
	end)

	Create("TextLabel", { Text = "The plugin never stores an AI key — it calls a secure backend that holds the provider credentials. All requests are validated, rate-limited and sent over HTTPS.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	-- Danger Zone: full place reset.
	Create("TextLabel", { Text = "⚠️ Danger Zone", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Error, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = view })
	Create("TextLabel", { Text = "Refresh place — permanently removes ALL scripts, models, GUIs and assets across Workspace, ServerScriptService, ReplicatedStorage, StarterGui, StarterPlayer, Lighting and more. The Baseplate is kept. Undo the whole wipe with Ctrl+Z.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	local resetBtn = button("🔄 Refresh place (keep Baseplate)", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.Error, TextColor3 = C.Bg })
	resetBtn.Parent = view
	local armed = false
	local resetToken = 0
	resetBtn.Activated:Connect(function()
		if not armed then
			armed = true
			resetBtn.Text = "⚠️ Click again to confirm wipe"
			resetToken += 1
			local myToken = resetToken
			task.delay(4, function()
				if armed and myToken == resetToken then
					armed = false
					resetBtn.Text = "🔄 Refresh place (keep Baseplate)"
				end
			end)
			return
		end
		armed = false
		resetToken += 1
		resetBtn.Text = "🔄 Refresh place (keep Baseplate)"
		local res = self.deps.apply:resetPlace(true)
		if res.ok then
			self:toast(("Place refreshed — removed %d item(s). Ctrl+Z to undo."):format(res.removed or 0), "success")
		else
			self:toast("Refresh failed: " .. (res.error or "unknown"), "error")
		end
	end)

	Create("TextLabel", { Text = ("Bloxsmith v%s"):format(Config.Version), Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), Parent = view })
end

--========================================================================
-- Changelog (what's new in each version)
--========================================================================
function App:buildChangelogView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = C.Border, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = view })
	pad(0).Parent = view

	Create("TextLabel", { Text = ("📝 What's New — Bloxsmith v%s"):format(Config.Version), Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0, Parent = view })

	for i, entry in ipairs(Config.Changelog or {}) do
		local isLatest = (i == 1)
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = view }, { corner(UDim.new(0, 8)), pad(10), stroke(isLatest and C.Accent or C.Border) })
		Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

		local header = ("v%s — %s"):format(entry.version, entry.title or "")
		if isLatest then header = "⭐ " .. header .. "  (latest)" end
		Create("TextLabel", { Text = header, Font = Theme.FontBold, TextSize = 14, TextColor3 = isLatest and C.Accent or C.Text, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 0, Parent = card })
		Create("TextLabel", { Text = entry.date or "", Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1, Parent = card })

		for j, change in ipairs(entry.changes or {}) do
			Create("TextLabel", { Text = "• " .. change, Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1 + j, Parent = card })
		end
	end
end


--========================================================================
-- Navigation + mount
--========================================================================
function App:selectView(name)
	self.currentView = name
	for viewName, frame in pairs(self.views) do
		frame.Visible = (viewName == name)
	end
	for viewName, btn in pairs(self.navButtons) do
		btn.BackgroundColor3 = (viewName == name) and C.Accent or C.Sidebar
		btn.TextColor3 = (viewName == name) and C.Text or C.TextDim
	end
	if name == "Errors" and self._renderErrors then
		self._renderErrors()
	end
end

function App:refreshSelectionStrip()
	if not self.contextLabel then
		return
	end
	local sel = self.deps.context:getSelection()
	if #sel == 0 then
		self.contextLabel.Text = "📍 No selection"
	else
		local names = {}
		for _, s in ipairs(sel) do
			table.insert(names, s.name .. " (" .. s.class .. ")")
		end
		self.contextLabel.Text = "📍 " .. table.concat(names, ", ")
	end
end

function App:mount(gui)
	self.gui = gui
	gui.BackgroundColor3 = C.Bg
	Create("UICorner", { CornerRadius = UDim.new(0, 0), Parent = gui })

	-- Toast holder (overlay)
	self.toastHolder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 260, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -270, 0, 10),
		ZIndex = 50,
		Parent = gui,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = self.toastHolder })

	-- Sidebar
	local sidebar = Create("Frame", { BackgroundColor3 = C.Sidebar, Size = UDim2.new(0, 118, 1, 0), BorderSizePixel = 0, Parent = gui })
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = sidebar })
	pad(8).Parent = sidebar

	Create("TextLabel", { Text = "🔨 Bloxsmith", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = sidebar })
	Create("TextLabel", { Text = ("v%s"):format(Config.Version), Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Parent = sidebar })

	-- Content area
	local content = Create("Frame", { BackgroundColor3 = C.Bg, Size = UDim2.new(1, -118, 1, 0), Position = UDim2.new(0, 118, 0, 0), BorderSizePixel = 0, Parent = gui }, { pad(10) })

	local nav = { "Chat", "Tools", "Toolbox", "Analysis", "Health", "Errors", "Changelog", "Settings" }
	for _, name in ipairs(nav) do
		local b = button(name, { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.Sidebar, TextColor3 = C.TextDim })
		b.Parent = sidebar
		b.Activated:Connect(function()
			self:selectView(name)
		end)
		self.navButtons[name] = b

		local frame = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = content })
		self.views[name] = frame
	end

	self:buildChatView(self.views.Chat)
	self:buildToolsView(self.views.Tools)
	self:buildToolboxView(self.views.Toolbox)
	self:buildAnalysisView(self.views.Analysis)
	self:buildHealthView(self.views.Health)
	self:buildErrorsView(self.views.Errors)
	self:buildChangelogView(self.views.Changelog)
	self:buildSettingsView(self.views.Settings)

	self:selectView("Chat")
	-- Restore the previous conversation (memory). Only greet on a fresh start.
	local restored = self:restoreActiveSession()
	if restored then
		self:toast("Restored your last conversation.", "success")
	else
		self:addBubble("assistant", "👋 **Welcome to Bloxsmith!** I can generate scripts, UIs and full game systems, build anything in Studio, fix & optimize code, and insert free models from the **Toolbox** tab. I remember our conversation across sessions. You'll see my 💭 thinking as I work, and you approve every change. Ask me anything!")
	end

	-- First-run guided tour.
	self:maybeShowTour()
end

-- One-time onboarding tour shown on first launch (dismissible, persisted).
function App:maybeShowTour()
	local seen = false
	pcall(function()
		seen = self.deps.plugin:GetSetting("Bloxsmith_TourSeen") and true or false
	end)
	if seen or not self.gui then
		return
	end

	local steps = {
		{ "👋 Welcome to Bloxsmith", "Your AI copilot for Roblox Studio. Take 20 seconds to see what it can do." },
		{ "💬 Chat & Generate", "Describe anything — 'build a shop', 'add a leaderboard' — and approve the changes. Tap the quick-action chips above the input for instant builds." },
		{ "🧰 Toolbox", "Search thousands of free models and insert them straight into your game. Favorite (☆) and re-insert them with one click, or use Insert-all." },
		{ "🛠 Tools & Auto-fix", "Generate systems and UIs, save prompt presets, and one-tap fix errors from the Errors tab or the 🔧 chip." },
		{ "🎨 Make it yours", "Set the AI's personality, response length and custom instructions in Settings. Enjoy building!" },
	}

	local overlay = Create("Frame", {
		BackgroundColor3 = C.Bg, BackgroundTransparency = 0.2, Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 100, Parent = self.gui,
	})
	local card = Create("Frame", {
		BackgroundColor3 = C.Panel, Size = UDim2.new(0, 300, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, -150, 0.35, 0), ZIndex = 101, Parent = overlay,
	}, { corner(UDim.new(0, 10)), pad(14), stroke(C.Accent) })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	local title = Create("TextLabel", {
		Text = "", Font = Theme.FontBold, TextSize = 16, TextColor3 = C.Accent, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), ZIndex = 101, LayoutOrder = 0, Parent = card,
	})
	local body = Create("TextLabel", {
		Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = C.TextDim, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), ZIndex = 101, LayoutOrder = 1, Parent = card,
	})
	local progress = Create("TextLabel", {
		Text = "", Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), ZIndex = 101, LayoutOrder = 2, Parent = card,
	})

	local btnRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), ZIndex = 101, LayoutOrder = 3, Parent = card })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), Parent = btnRow })

	local idx = 1
	local function finish()
		pcall(function()
			self.deps.plugin:SetSetting("Bloxsmith_TourSeen", true)
		end)
		overlay:Destroy()
	end

	local skip = button("Skip", { Size = UDim2.new(0, 70, 1, 0), BackgroundColor3 = C.PanelAlt, TextSize = 12 })
	skip.ZIndex = 101
	skip.Parent = btnRow
	skip.Activated:Connect(finish)

	local next = button("Next", { Size = UDim2.new(0, 90, 1, 0), TextSize = 12 })
	next.ZIndex = 101
	next.Parent = btnRow

	local function render()
		local step = steps[idx]
		title.Text = step[1]
		body.Text = step[2]
		progress.Text = ("Step %d of %d"):format(idx, #steps)
		next.Text = (idx == #steps) and "Get started" or "Next"
	end
	next.Activated:Connect(function()
		if idx >= #steps then
			finish()
		else
			idx += 1
			render()
		end
	end)
	render()
end

return App
end

_modules["UI.Create"] = function()

--[[
	Create.lua — declarative Instance builder to keep UI code readable.
	Usage:
	  Create("TextButton", { Text = "Hi", Parent = frame }, {
	      Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
	  })
]]
local function Create(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

return Create
end

_modules["UI.Theme"] = function()

--[[ Theme.lua — single source of truth for the premium dark UI palette & spacing.
	Matches the Bloxsmith brand: deep navy backgrounds with an electric blue → cyan accent. ]]
local Theme = {}

Theme.Color = {
	-- Deep navy surfaces (match the website's premium blue theme)
	Bg = Color3.fromRGB(9, 12, 22),
	BgAlt = Color3.fromRGB(13, 17, 30),
	Panel = Color3.fromRGB(18, 24, 40),
	PanelAlt = Color3.fromRGB(24, 32, 52),
	Border = Color3.fromRGB(38, 50, 78),
	Sidebar = Color3.fromRGB(11, 15, 27),

	Text = Color3.fromRGB(236, 242, 255),
	TextDim = Color3.fromRGB(148, 163, 196),
	TextFaint = Color3.fromRGB(96, 110, 142),

	-- Electric blue → cyan accent
	Accent = Color3.fromRGB(45, 121, 255),
	Accent2 = Color3.fromRGB(34, 211, 238),
	AccentDim = Color3.fromRGB(28, 64, 128),

	UserBubble = Color3.fromRGB(22, 45, 82),
	AiBubble = Color3.fromRGB(18, 24, 40),

	Success = Color3.fromRGB(52, 211, 153),
	Warning = Color3.fromRGB(251, 191, 36),
	Error = Color3.fromRGB(248, 113, 113),
	Info = Color3.fromRGB(56, 189, 248),
}

Theme.Font = Enum.Font.Gotham
Theme.FontMedium = Enum.Font.GothamMedium
Theme.FontBold = Enum.Font.GothamBold
Theme.FontMono = Enum.Font.Code

Theme.Pad = 10
Theme.Radius = UDim.new(0, 8)

function Theme.severityColor(sev)
	sev = string.lower(sev or "")
	if sev == "critical" or sev == "high" then
		return Theme.Color.Error
	elseif sev == "medium" then
		return Theme.Color.Warning
	elseif sev == "low" then
		return Theme.Color.Info
	end
	return Theme.Color.TextDim
end

function Theme.scoreColor(score)
	if score >= 80 then
		return Theme.Color.Success
	elseif score >= 55 then
		return Theme.Color.Warning
	end
	return Theme.Color.Error
end

return Theme
end

_modules["Util.Log"] = function()

--[[ Log.lua — namespaced, level-aware logging so output is easy to filter. ]]
local Log = {}

local PREFIX = "[Bloxsmith]"

function Log.info(...)
	print(PREFIX, ...)
end

function Log.warn(...)
	warn(PREFIX, ...)
end

function Log.error(...)
	warn(PREFIX, "ERROR:", ...)
end

-- Wrap a risky call, log failures, and return (ok, resultOrErr).
function Log.try(label, fn, ...)
	local ok, res = pcall(fn, ...)
	if not ok then
		Log.error(label, "->", res)
	end
	return ok, res
end

return Log
end

_modules["Util.Parser"] = function()

--[[
	Parser.lua
	Turns AI markdown replies into actionable pieces:
	- extractBlocks: fenced code blocks with optional `path= name= class=` hints,
	  converted into apply-ready action tables.
]]
local Parser = {}

-- Parse a fence header like: lua path=ServerScriptService/Shop name=Shop class=Script
local function parseHeader(header)
	local meta = { lang = "lua" }
	local firstWord = string.match(header, "^%s*([%w_+-]+)")
	if firstWord then
		meta.lang = firstWord
	end
	for key, value in string.gmatch(header, "(%w+)=([^%s]+)") do
		meta[key] = value
	end
	return meta
end

-- Returns an array of { source, lang, path, name, class }.
function Parser.extractBlocks(text)
	local blocks = {}
	if type(text) ~= "string" then
		return blocks
	end
	-- Match ```<header>\n<body>```
	for header, body in string.gmatch(text, "```([^\n]*)\n([%s%S]-)```") do
		local meta = parseHeader(header)
		if meta.lang == "bloxsmith:actions" or meta.lang == "bloxsmith:thinking" then
			-- handled separately (agent actions / thinking panel); skip here.
		else
			table.insert(blocks, {
				source = body,
				lang = meta.lang,
				path = meta.path,
				name = meta.name,
				class = meta.class,
			})
		end
	end
	return blocks
end

-- Extract the leading ```bloxsmith:thinking ... ``` block (the AI's plan).
-- Returns (thinkingText or nil, textWithThinkingRemoved).
function Parser.extractThinking(text)
	if type(text) ~= "string" then
		return nil, text
	end
	local thinking = string.match(text, "```bloxsmith:thinking%s*\n([%s%S]-)```")
	if thinking then
		local cleaned = string.gsub(text, "```bloxsmith:thinking%s*\n[%s%S]-```", "", 1)
		return (thinking:gsub("^%s+", ""):gsub("%s+$", "")), cleaned
	end
	return nil, text
end

-- Repairs JS-style single-quoted JSON without corrupting content. A blind
-- '->" replace breaks the moment generated code contains an apostrophe
-- (e.g. "it's", "player's Tool") — this walks the string tracking quote
-- state so only quotes acting as string *delimiters* get converted; a `'`
-- that reads as a literal apostrophe (not followed by a JSON structural
-- character) is left alone, and any real `"` found inside a converted
-- string gets escaped so it doesn't terminate early.
local function smartSingleQuoteRepair(json)
	local out, i, n = {}, 1, #json
	local inDouble, inSingle = false, false
	while i <= n do
		local c = json:sub(i, i)
		if c == "\\" and i < n then
			out[#out + 1] = c
			out[#out + 1] = json:sub(i + 1, i + 1)
			i = i + 2
		elseif inDouble then
			if c == '"' then inDouble = false end
			out[#out + 1] = c
			i = i + 1
		elseif inSingle then
			if c == "'" then
				local j = i + 1
				while j <= n and json:sub(j, j):match("%s") do j = j + 1 end
				local nextCh = json:sub(j, j)
				if nextCh == "" or nextCh == "," or nextCh == "}" or nextCh == "]" or nextCh == ":" then
					out[#out + 1] = '"'
					inSingle = false
				else
					out[#out + 1] = "'" -- literal apostrophe; unescaped ' is valid inside a JSON string
				end
			elseif c == '"' then
				out[#out + 1] = '\\"'
			else
				out[#out + 1] = c
			end
			i = i + 1
		else
			if c == '"' then
				inDouble = true
				out[#out + 1] = c
			elseif c == "'" then
				inSingle = true
				out[#out + 1] = '"'
			else
				out[#out + 1] = c
			end
			i = i + 1
		end
	end
	return table.concat(out)
end

-- Extract JSON actions from a ```bloxsmith:actions ... ``` block as a safety net
-- in case the backend returns a reply but fails to populate decoded.actions.
-- Returns (actionsTable or nil, textWithActionsRemoved, foundBlock).
function Parser.extractActions(text)
	if type(text) ~= "string" then
		return nil, text, false
	end
	local json = string.match(text, "```bloxsmith:actions%s*\n([%s%S]-)```")
	if not json or json == "" then
		return nil, text, false
	end
	local cleaned = string.gsub(text, "```bloxsmith:actions%s*\n[%s%S]-```", "", 1)

	local HttpService = game:GetService("HttpService")

	-- 1) Try as-is first — the common case, and zero risk of corrupting code.
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if ok and type(decoded) == "table" then
		return decoded, cleaned, true
	end

	-- 2) Strip trailing commas, a common small LLM slip.
	local noTrailingCommas = (json:gsub(",(%s*[%]}])", "%1"))
	local ok2, decoded2 = pcall(function()
		return HttpService:JSONDecode(noTrailingCommas)
	end)
	if ok2 and type(decoded2) == "table" then
		return decoded2, cleaned, true
	end

	-- 3) Quote-aware repair for JS-style single-quoted objects (see above) —
	--    only used as a last resort, and safe for apostrophes in code.
	local repaired = smartSingleQuoteRepair(noTrailingCommas)
	local ok3, decoded3 = pcall(function()
		return HttpService:JSONDecode(repaired)
	end)
	if ok3 and type(decoded3) == "table" then
		return decoded3, cleaned, true
	end

	warn("[Bloxsmith Action Parser Error]: Failed to parse actions JSON block.")
	warn("Error (raw):", tostring(decoded))
	warn("Error (repaired):", tostring(decoded3))
	print("[Bloxsmith Malformed Actions JSON]:\n" .. tostring(json))

	return nil, cleaned, true
end

-- Convert a code block into a create_script action (best-effort defaults).
function Parser.blockToAction(block, index)
	local class = block.class
	if class ~= "Script" and class ~= "LocalScript" and class ~= "ModuleScript" then
		-- Infer from content.
		if string.find(block.source, "game.Players.LocalPlayer") or string.find(block.source, "PlayerGui") then
			class = "LocalScript"
		elseif string.find(block.source, "return%s") and not string.find(block.source, "OnServerEvent") then
			class = "ModuleScript"
		else
			class = "Script"
		end
	end
	local path = block.path
	local name = block.name
	if path and not name then
		-- If the path includes the script name as last segment, split it out.
		local segs = string.split(path, "/")
		if #segs > 1 then
			name = segs[#segs]
			table.remove(segs, #segs)
			path = table.concat(segs, "/")
		end
	end
	return {
		action = "create_script",
		path = path or (class == "LocalScript" and "StarterPlayer/StarterPlayerScripts" or "ServerScriptService"),
		name = name or ("BloxsmithScript" .. tostring(index or 1)),
		class = class,
		source = block.source,
	}
end

-- Escape the characters that are special inside a Roblox RichText string.
local function escapeRich(s)
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end

--[[
	toRichText(text, opts) -> string
	Converts a subset of Markdown into Roblox RichText so AI replies render as
	clean formatted text instead of raw **asterisks**, #hashes and `backticks`.

	Supported:
	  # / ## / ###  headers        -> bold (larger via <font size>)
	  **bold**  / __bold__          -> <b>…</b>
	  *italic*  / _italic_          -> <i>…</i>
	  `inline code`                 -> colored monospace-style span
	  - / * / • bullets             -> • bullet
	  1. numbered lists             -> kept as "1." with a thin space
	  ---/*** horizontal rules      -> a subtle divider line
	opts.codeColor = "#RRGGBB" for inline code (defaults to a soft cyan).
]]
function Parser.toRichText(text, opts)
	if type(text) ~= "string" then
		return ""
	end
	opts = opts or {}
	local codeColor = opts.codeColor or "#8be9fd"

	-- Escape first so user/AI angle brackets never inject tags.
	local out = escapeRich(text)

	-- Process line-by-line for block-level markdown (headers, bullets, rules).
	local lines = string.split(out, "\n")
	for i, line in ipairs(lines) do
		local trimmed = line:gsub("^%s+", "")

		-- Horizontal rule.
		if trimmed:match("^%-%-%-+$") or trimmed:match("^%*%*%*+$") or trimmed:match("^___+$") then
			lines[i] = '<font color="#3a4356">──────────</font>'
		else
			-- Headers (#, ##, ###) -> bold, slightly larger for the biggest.
			local hashes, htext = line:match("^%s*(#+)%s+(.*)$")
			if hashes then
				local size = #hashes == 1 and 17 or (#hashes == 2 and 15 or 14)
				lines[i] = ('<font size="%d"><b>%s</b></font>'):format(size, htext)
			else
				-- Bullets: "- ", "* ", "+ " -> "• "
				local indent, btext = line:match("^(%s*)[%-%*%+]%s+(.*)$")
				if btext then
					lines[i] = indent .. "• " .. btext
				end
			end
		end
	end
	out = table.concat(lines, "\n")

	-- Inline code first so ** or * inside code isn't reinterpreted.
	out = out:gsub("`([^`]+)`", '<font color="' .. codeColor .. '">%1</font>')

	-- Bold (** or __) before italic so the ** pair wins over single *.
	out = out:gsub("%*%*(.-)%*%*", "<b>%1</b>")
	out = out:gsub("__(.-)__", "<b>%1</b>")

	-- Italic (single * or _). Require non-space next to the marker so it does
	-- not eat stray asterisks.
	out = out:gsub("%*(%S.-%S)%*", "<i>%1</i>")
	out = out:gsub("%*(%S)%*", "<i>%1</i>")

	return out
end

return Parser
end

_modules["Util.Signal"] = function()

--[[ Signal.lua — tiny event implementation for decoupling services from UI. ]]
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handlers = self._handlers
	handlers[fn] = true
	return {
		Disconnect = function()
			handlers[fn] = nil
		end,
	}
end

function Signal:Fire(...)
	for fn in pairs(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
end

-- ===== Plugin bootstrap (init.server) =====
--[[
	Bloxsmith — init.server.lua
	Plugin bootstrap: creates the toolbar button + dock widget, instantiates the
	service layer, and mounts the UI. All heavy lifting lives in the modules under
	Services/ and UI/ to keep this entry point thin and maintainable.
]]
local Selection = game:GetService("Selection")

local Config = _R("Config")
local Log = _R("Util.Log")

-- Services
local AIService = _R("Services.AIService")
local ContextService = _R("Services.ContextService")
local ApplyService = _R("Services.ApplyService")
local SecurityScanner = _R("Services.SecurityScanner")
local PerformanceAnalyzer = _R("Services.PerformanceAnalyzer")
local CleanupService = _R("Services.CleanupService")
local ErrorMonitor = _R("Services.ErrorMonitor")
local HealthService = _R("Services.HealthService")

-- UI
local App = _R("UI.App")

Log.info(("v%s loading…"):format(Config.Version))

-- Toolbar + button
local toolbar = plugin:CreateToolbar("Bloxsmith")
local toggleButton = toolbar:CreateButton(
	"Bloxsmith",
	"Open the Bloxsmith AI copilot",
	"rbxasset://textures/ui/GuiImagePlaceholder.png"
)
toggleButton.ClickableWhenViewportHidden = true

-- Dock widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false, -- start closed
	false,
	420, -- default width
	560, -- default height
	340, -- min width
	400 -- min height
)
local widget = plugin:CreateDockWidgetPluginGui("BloxsmithMain", widgetInfo)
widget.Title = "Bloxsmith — AI Copilot"
widget.Name = "BloxsmithMain"

-- Instantiate service layer
local security = SecurityScanner.new()
local performance = PerformanceAnalyzer.new()
local cleanup = CleanupService.new()

local deps = {
	plugin = plugin,
	ai = AIService.new(plugin),
	context = ContextService.new(),
	security = security,
	performance = performance,
	cleanup = cleanup,
	errors = ErrorMonitor.new(),
	health = HealthService.new(security, performance, cleanup),
}
deps.apply = ApplyService.new(deps.context)

deps.errors:start()

-- Root gui frame inside the widget
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = Config and Color3.fromRGB(18, 18, 24)
root.BorderSizePixel = 0
root.Parent = widget

local app = App.new(deps)
app:mount(root)

-- Keep the selection strip live
Selection.SelectionChanged:Connect(function()
	pcall(function()
		app:refreshSelectionStrip()
	end)
end)

-- Toggle behavior
local function updateButton()
	toggleButton:SetActive(widget.Enabled)
end

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	updateButton()
end)
widget:GetPropertyChangedSignal("Enabled"):Connect(updateButton)
updateButton()

-- Clean shutdown
plugin.Unloading:Connect(function()
	pcall(function()
		app:saveCurrentConversation()
	end)
	deps.errors:stop()
	Log.info("unloaded.")
end)

Log.info("ready.")
