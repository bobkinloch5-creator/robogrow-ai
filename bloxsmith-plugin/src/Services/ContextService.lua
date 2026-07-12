--[[
	ContextService.lua
	Gives the AI project-wide understanding: selection details, script sources,
	and a summarized hierarchy of the important services. Kept bounded for perf.
]]
local Selection = game:GetService("Selection")
local Config = require(script.Parent.Parent.Config)

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

function ContextService.new()
	return setmetatable({}, ContextService)
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
			info.source = string.sub(src, 1, 6000)
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
		if #out >= 12 then
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

-- Bounded walk producing a lightweight tree + counts.
function ContextService:getProjectTree()
	local budget = Config.MaxContextInstances
	local counts = { scripts = 0, parts = 0, guis = 0, remotes = 0, total = 0 }

	local function walk(inst, depth)
		if budget <= 0 or depth > 4 then
			return nil
		end
		local node = { name = inst.Name, class = inst.ClassName }
		local kids = inst:GetChildren()
		local childNodes = {}
		for _, child in ipairs(kids) do
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
			if budget <= 0 then
				break
			end
			local sub = walk(child, depth + 1)
			if sub then
				table.insert(childNodes, sub)
			end
		end
		if #childNodes > 0 then
			node.children = childNodes
		end
		return node
	end

	local tree = {}
	for _, svcName in ipairs(INSPECTED_SERVICES) do
		local ok, svc = pcall(function()
			return game:GetService(svcName)
		end)
		if ok and svc then
			table.insert(tree, walk(svc, 0))
		end
	end
	return { tree = tree, counts = counts }
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
