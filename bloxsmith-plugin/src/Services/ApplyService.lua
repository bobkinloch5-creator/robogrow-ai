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
	  create_instance  { path, class, name, properties? }
	  set_property      { target, property, value }
	  rename_instance  { target, name }
	  delete_instance  { target }
	  move_instance    { target, path }
]]
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local Log = require(script.Parent.Parent.Util.Log)

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


function ApplyService.new()
	return setmetatable({}, ApplyService)
end

-- Resolve "ServerScriptService/Systems/Shop" into an Instance, creating folders as needed.
function ApplyService:resolvePath(path, createFolders)
	if type(path) ~= "string" or path == "" then
		return nil
	end
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
		if segname ~= "" then
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
	end
	return current
end

-- Best-effort coercion of a JSON value into a Roblox property value.
local function coerceValue(inst, property, value)
	local existing = inst[property]
	local t = typeof(existing)
	if t == "Color3" and type(value) == "table" then
		return Color3.fromRGB(value.r or value[1] or 0, value.g or value[2] or 0, value.b or value[3] or 0)
	elseif t == "Vector3" and type(value) == "table" then
		return Vector3.new(value.x or value[1] or 0, value.y or value[2] or 0, value.z or value[3] or 0)
	elseif t == "UDim2" and type(value) == "table" then
		return UDim2.new(value[1] or 0, value[2] or 0, value[3] or 0, value[4] or 0)
	elseif t == "number" then
		return tonumber(value) or existing
	elseif t == "boolean" then
		return value and true or false
	elseif t == "string" then
		return tostring(value)
	elseif t == "EnumItem" and type(value) == "string" then
		-- e.g. "Enum.Material.Neon" or "Neon"
		local enumName = existing.EnumType.Name
		local leaf = string.match(value, "([%w_]+)$") or value
		local ok, enumVal = pcall(function()
			return Enum[enumName][leaf]
		end)
		if ok then
			return enumVal
		end
	end
	return value
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
		local class = SCRIPT_CLASSES[action.class] and action.class or "Script"
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

	elseif kind == "create_instance" then
		local class = action.class
		if not class or not CREATE_WHITELIST[class] then
			return false, "Refused to create disallowed class: " .. tostring(class)
		end
		local parent = self:resolvePath(action.path or "Workspace", true)
		local okNew, inst = pcall(Instance.new, class)
		if not okNew or not inst then
			return false, "Could not create instance of class " .. tostring(class)
		end
		inst.Name = action.name or class
		if type(action.properties) == "table" then
			for prop, val in pairs(action.properties) do
				pcall(function()
					inst[prop] = coerceValue(inst, prop, val)
				end)
			end
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

	return { ok = not anyFail, results = results, created = created, applied = okCount }
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
