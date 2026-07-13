
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
				if string.find(src, rule[1]) then
					-- Refine: a while-true with a wait inside is fine.
					if not (rule[3] == "possible unyielding loop" and string.find(src, "task%.wait")) then
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

