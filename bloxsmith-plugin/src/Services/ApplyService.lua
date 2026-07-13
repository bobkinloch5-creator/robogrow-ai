
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

