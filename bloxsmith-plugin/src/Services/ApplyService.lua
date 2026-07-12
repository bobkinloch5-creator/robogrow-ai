--[[
	ApplyService.lua
	Applies AI-generated changes to the DataModel with full undo/redo support.
	Every batch is wrapped in a ChangeHistoryService recording so a single Ctrl+Z
	reverts the whole operation. Nothing here runs without explicit user approval
	from the UI layer.
]]
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local Log = require(script.Parent.Parent.Util.Log)

local ApplyService = {}
ApplyService.__index = ApplyService

local CLASS_WHITELIST = { Script = true, LocalScript = true, ModuleScript = true }

function ApplyService.new()
	return setmetatable({}, ApplyService)
end

-- Resolve "ServerScriptService/Systems/Shop" into an Instance, creating folders as needed.
function ApplyService:resolvePath(path, createFolders)
	local segments = string.split(path, "/")
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
		local nextInst = current:FindFirstChild(segname)
		if not nextInst then
			if not createFolders then
				return nil
			end
			nextInst = Instance.new("Folder")
			nextInst.Name = segname
			nextInst.Parent = current
		end
		current = nextInst
	end
	return current
end

-- Apply one action. Returns (ok, message, instance?).
function ApplyService:applyOne(action)
	local kind = action.action
	if kind == "create_folder" then
		local parent = self:resolvePath(action.path or "Workspace", true)
		local folder = Instance.new("Folder")
		folder.Name = action.name or "Folder"
		folder.Parent = parent
		return true, "Created folder " .. folder:GetFullName(), folder
	elseif kind == "create_script" then
		local class = CLASS_WHITELIST[action.class] and action.class or "Script"
		local parent = self:resolvePath(action.path or "ServerScriptService", true)
		local inst = Instance.new(class)
		inst.Name = action.name or "BloxsmithScript"
		inst.Source = action.source or "-- (empty)"
		inst.Parent = parent
		return true, "Created " .. class .. " " .. inst:GetFullName(), inst
	elseif kind == "replace_script" then
		local target = self:resolvePath(action.target or "", false)
		if not target or not target:IsA("LuaSourceContainer") then
			return false, "Could not find script to replace: " .. tostring(action.target)
		end
		target.Source = action.source or target.Source
		return true, "Updated " .. target:GetFullName(), target
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

	for _, action in ipairs(actions) do
		local ok, msg, inst = self:applyOne(action)
		table.insert(results, { ok = ok, message = msg })
		if ok and inst then
			table.insert(created, inst)
		end
		if not ok then
			anyFail = true
			Log.warn("Action failed:", msg)
		end
	end

	if recordId then
		ChangeHistoryService:FinishRecording(
			recordId,
			Enum.FinishRecordingOperation.Commit
		)
	end

	if #created > 0 then
		pcall(function()
			Selection:Set(created)
		end)
	end

	return { ok = not anyFail, results = results, created = created }
end

-- Overwrite a specific script's source with undo support (used by fix/optimize).
function ApplyService:replaceSource(scriptInstance, newSource, label)
	if not scriptInstance or not scriptInstance:IsA("LuaSourceContainer") then
		return { ok = false, error = "No valid script selected." }
	end
	local recordId = ChangeHistoryService:TryBeginRecording(label or "Bloxsmith edit script")
	scriptInstance.Source = newSource
	if recordId then
		ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
	end
	return { ok = true }
end

return ApplyService
