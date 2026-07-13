
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
