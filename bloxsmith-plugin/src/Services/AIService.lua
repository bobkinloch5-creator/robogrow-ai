--[[
	AIService.lua
	The scalable service layer between the plugin and the AI backend.
	- Provider-agnostic: the backend decides which model/provider answers.
	- Secure: no API key is stored here; only the public backend URL + anon key.
	- Robust: full error handling, timeouts, typed results, and automatic
	  retries with exponential backoff for transient failures.
]]
local HttpService = game:GetService("HttpService")

local Config = require(script.Parent.Parent.Config)
local Log = require(script.Parent.Parent.Util.Log)

local AIService = {}
AIService.__index = AIService

local MAX_RETRIES = 2 -- total attempts = MAX_RETRIES + 1
local RETRYABLE_STATUS = { [429] = true, [500] = true, [502] = true, [503] = true, [504] = true }

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
	local instructions = get(Config.Settings.CustomInstructions, Config.Defaults.CustomInstructions)
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
		return {
			ok = false,
			retryable = true,
			error = "Network error. Enable HTTP requests (allow the permission prompt) and check the backend URL in Settings.",
		}
	end

	local decoded
	local decodeOk = pcall(function()
		decoded = HttpService:JSONDecode(response.Body)
	end)

	if not response.Success then
		local msg = (decodeOk and decoded and decoded.error)
			or ("Backend error " .. tostring(response.StatusCode))
		return { ok = false, retryable = RETRYABLE_STATUS[response.StatusCode] == true, error = msg }
	end

	if not decodeOk or not decoded then
		return { ok = false, retryable = false, error = "Received a malformed response from the backend." }
	end

	if decoded.error then
		return { ok = false, retryable = false, error = decoded.error }
	end

	return {
		ok = true,
		reply = decoded.reply or "",
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
			local backoff = 0.8 * (2 ^ attempt)
			Log.warn(("Transient failure, retrying in %.1fs (attempt %d/%d)…"):format(backoff, attempt + 1, MAX_RETRIES))
			task.wait(backoff)
		end
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
		return HttpService:JSONEncode({ mode = "toolbox_search", query = query, limit = limit })
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
