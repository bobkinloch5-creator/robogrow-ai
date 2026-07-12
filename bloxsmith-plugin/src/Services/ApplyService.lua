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
		if type(class) ~= "string" or class == "" then
			return false, "create_instance requires a class name"
		end
		if CREATE_BLACKLIST[class] then
			return false, "Refused to create protected/service class: " .. tostring(class)
		end
		local parent = self:resolvePath(action.path or "Workspace", true)
		local okNew, inst = pcall(Instance.new, class)
		if not okNew or not inst then
			return false, "Roblox cannot create an instance of class: " .. tostring(class)
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
			local target, isVisual = smartParentFor(child, requestedParent)
			pcall(function()
				child.Parent = target
			end)
			table.insert(placed, child)
			if isVisual then
				table.insert(visualParts, child)
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

		-- Move any visual model in front of the camera and focus it so the user
		-- immediately SEES it (models otherwise spawn at the world origin).
		pcall(function()
			local camera = workspace.CurrentCamera
			for _, obj in ipairs(visualParts) do
				if camera and (obj:IsA("Model") or obj:IsA("BasePart")) then
					local okPivot = pcall(function()
						obj:PivotTo(CFrame.new(camera.CFrame.Position + camera.CFrame.LookVector * 20))
					end)
					if okPivot then
						camera.CFrame = CFrame.lookAt(camera.CFrame.Position, obj:GetPivot().Position)
					end
					break
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

	return { ok = not anyFail, results = results, created = created, applied = okCount, error = firstError }
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
	return { ok = true, removed = removed }
end

return ApplyService
