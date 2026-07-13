
--[[
	ContextService.lua
	Gives the AI project-wide understanding: selection details, script sources,
	and a summarized hierarchy of the important services. Kept bounded for perf.
]]
local Selection = game:GetService("Selection")
local Config = _R("Config")

local ContextService = {}
ContextService.__index = ContextService

local INSPECTED_SERVICES = {
	"Workspace",
	"ServerScriptService",
	"ServerStorage",
	"ReplicatedStorage",
	"StarterGui",
	"StarterPlayer",
	"StarterPack",
	"Lighting",
}

-- Tree walks over big places are the single most expensive thing Bloxsmith
-- does per-request. Cache the result for a short window and reuse it across
-- consecutive messages instead of re-walking the whole DataModel every time —
-- this is the biggest lever on perceived "generation speed" for agent /
-- generate modes on large places.
local TREE_CACHE_TTL = 12 -- seconds

function ContextService.new()
	return setmetatable({ _treeCache = nil, _treeCacheAt = 0 }, ContextService)
end

local function fullName(inst)
	return inst:GetFullName()
end

-- Summarize a single instance for the AI (compact).
local function describe(inst)
	local info = { name = inst.Name, class = inst.ClassName, path = fullName(inst) }
	if inst:IsA("LuaSourceContainer") then
		local ok, src = pcall(function()
			return inst.Source
		end)
		if ok then
			if #src > 6000 then
				info.source = string.sub(src, 1, 6000) .. "\n--[[ ...TRUNCATED: script is " .. #src .. " chars, only the first 6000 shown to the AI... ]]"
			else
				info.source = src
			end
		end
	elseif inst:IsA("BasePart") then
		info.size = tostring(inst.Size)
		info.anchored = inst.Anchored
	end
	return info
end

-- Details for whatever is selected in Studio right now.
function ContextService:getSelection()
	local sel = Selection:Get()
	local out = {}
	for _, inst in ipairs(sel) do
		table.insert(out, describe(inst))
		if #out >= (Config.MaxSelectionContext or 40) then
			break
		end
	end
	return out
end

-- First selected script instance (for fix/explain/optimize).
function ContextService:getSelectedScript()
	for _, inst in ipairs(Selection:Get()) do
		if inst:IsA("LuaSourceContainer") then
			return inst
		end
	end
	return nil
end

-- Bounded walk producing a lightweight tree + counts. Cached for
-- TREE_CACHE_TTL seconds so rapid back-to-back agent turns (the common case
-- while iterating on a build) reuse the same walk instead of paying the full
-- hierarchy-scan cost on every single message.
function ContextService:getProjectTree()
	local now = os.clock()
	if self._treeCache and (now - self._treeCacheAt) < TREE_CACHE_TTL then
		return self._treeCache
	end

	local budget = Config.MaxContextInstances
	local counts = { scripts = 0, parts = 0, guis = 0, remotes = 0, total = 0 }

	local function walk(inst, depth, localBudget)
		if localBudget <= 0 or depth > 4 then
			return nil, localBudget
		end
		local node = { name = inst.Name, class = inst.ClassName }
		local kids = inst:GetChildren()
		local childNodes = {}
		for _, child in ipairs(kids) do
			localBudget -= 1
			budget -= 1
			counts.total += 1
			if child:IsA("LuaSourceContainer") then
				counts.scripts += 1
			elseif child:IsA("BasePart") then
				counts.parts += 1
			elseif child:IsA("GuiObject") or child:IsA("ScreenGui") then
				counts.guis += 1
			elseif child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
				counts.remotes += 1
			end
			if localBudget <= 0 then
				break
			end
			local sub
			sub, localBudget = walk(child, depth + 1, localBudget)
			if sub then
				table.insert(childNodes, sub)
			end
		end
		if #childNodes > 0 then
			node.children = childNodes
		end
		return node, localBudget
	end

	local tree = {}
	-- Split the budget evenly across services up front so one big service
	-- (Workspace, on almost any real game) can't silently eat the entire
	-- walk and make every later service falsely look empty to the AI. Any
	-- unused share from an early, smaller service rolls forward to the rest.
	local perServiceBudget = math.max(1, math.floor(budget / #INSPECTED_SERVICES))
	for _, svcName in ipairs(INSPECTED_SERVICES) do
		local ok, svc = pcall(function()
			return game:GetService(svcName)
		end)
		if ok and svc then
			local thisBudget = math.min(perServiceBudget, math.max(budget, 0))
			local node, leftover = walk(svc, 0, thisBudget)
			-- Roll back whatever this service didn't use into the shared pool.
			if leftover and leftover > 0 then
				budget += leftover
			end
			table.insert(tree, node)
		end
	end
	local result = { tree = tree, counts = counts }
	self._treeCache = result
	self._treeCacheAt = now
	return result
end

-- Force the next getProjectTree() call to re-walk instead of using the
-- cache — called after Apply actions mutate the place, so the AI always
-- sees an up-to-date hierarchy right after a change.
function ContextService:invalidateTreeCache()
	self._treeCache = nil
end

-- Full context bundle for AI calls.
function ContextService:build(includeTree)
	local ctx = { selection = self:getSelection() }
	if includeTree then
		local proj = self:getProjectTree()
		ctx.counts = proj.counts
		ctx.hierarchy = proj.tree
	end
	return ctx
end

return ContextService
end

