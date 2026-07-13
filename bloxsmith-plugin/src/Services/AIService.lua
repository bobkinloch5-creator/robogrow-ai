
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
