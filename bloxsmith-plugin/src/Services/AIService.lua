--[[
	AIService.lua
	The scalable service layer between the plugin and the AI backend.
	- Provider-agnostic: the backend decides which model/provider answers.
	- Secure: no API key is stored here; only the public backend URL + anon key.
	- Robust: full error handling, timeouts, and typed results.
]]
local HttpService = game:GetService("HttpService")

local Config = require(script.Parent.Parent.Config)
local Log = require(script.Parent.Parent.Util.Log)

local AIService = {}
AIService.__index = AIService

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
	}

	local ok, body = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		return { ok = false, error = "Failed to encode request." }
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
		Log.error("HTTP request failed:", response)
		return {
			ok = false,
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
		return { ok = false, error = msg }
	end

	if not decodeOk or not decoded then
		return { ok = false, error = "Received a malformed response from the backend." }
	end

	if decoded.error then
		return { ok = false, error = decoded.error }
	end

	return { ok = true, reply = decoded.reply or "", actions = decoded.actions, provider = decoded.provider }
end

return AIService
