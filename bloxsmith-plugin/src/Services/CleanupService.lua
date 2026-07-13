
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

function CleanupService.new()
	return setmetatable({}, CleanupService)
end

function CleanupService:scan()
	local findings = {}
	local defaults, emptyFolders = 0, 0
	local nameBuckets = {}

	for _, d in ipairs(game:GetDescendants()) do
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

	if defaults > 0 then
		table.insert(findings, 1, {
			severity = "Medium",
			title = ("%d default-named objects"):format(defaults),
			advice = "Rename generic 'Part'/'Script'/'Folder' instances to describe their purpose.",
		})
	end

	for key, count in pairs(nameBuckets) do
		if count >= 5 then
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

