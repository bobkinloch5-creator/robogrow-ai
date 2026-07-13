
--[[
	PerformanceAnalyzer.lua
	Heuristics for lag sources: unthrottled loops, per-frame work, excessive
	instances, unanchored parts, and connection leaks. Returns findings + metrics.
]]
local Workspace = game:GetService("Workspace")

local PerformanceAnalyzer = {}
PerformanceAnalyzer.__index = PerformanceAnalyzer

function PerformanceAnalyzer.new()
	return setmetatable({}, PerformanceAnalyzer)
end

function PerformanceAnalyzer:analyze()
	local findings = {}
	local metrics = { parts = 0, unanchored = 0, unions = 0, meshes = 0, scripts = 0, instances = 0 }

	-- Single pass over the whole tree (this used to be two full
	-- game:GetDescendants() walks — merged into one for large places).
	for _, d in ipairs(game:GetDescendants()) do
		metrics.instances += 1
		if d:IsA("BasePart") then
			metrics.parts += 1
			if not d.Anchored and not d:FindFirstAncestorWhichIsA("Model") then
				metrics.unanchored += 1
			end
			if d:IsA("UnionOperation") then
				metrics.unions += 1
			elseif d:IsA("MeshPart") then
				metrics.meshes += 1
			end
		elseif d:IsA("LuaSourceContainer") then
			metrics.scripts += 1
			local ok, src = pcall(function()
				return d.Source
			end)
			if ok and src then
				if string.find(src, "while%s+true%s+do") and not string.find(src, "task%.wait") and not string.find(src, "RunService") then
					table.insert(findings, {
						severity = "High",
						title = "Unthrottled while-true loop",
						advice = "Add task.wait() or it will spike CPU and can freeze the client.",
						path = d:GetFullName(),
					})
				end
				if string.find(src, "Heartbeat:Connect") or string.find(src, "RenderStepped:Connect") then
					if string.find(src, ":FindFirstChild") or string.find(src, "Instance.new") then
						table.insert(findings, {
							severity = "Medium",
							title = "Heavy work every frame",
							advice = "Per-frame FindFirstChild/Instance.new allocates constantly. Cache references outside the loop.",
							path = d:GetFullName(),
						})
					end
				end
				if string.find(src, ":Connect") and not string.find(src, ":Disconnect") and not string.find(src, "Once") then
					table.insert(findings, {
						severity = "Low",
						title = "Possible connection leak",
						advice = "Connections are never disconnected — store & clean them up to avoid memory growth.",
						path = d:GetFullName(),
					})
				end
			end
		end
		if metrics.instances > 60000 then
			break
		end
	end

	if metrics.parts > 15000 then
		table.insert(findings, {
			severity = "High",
			title = ("High part count (%d)"):format(metrics.parts),
			advice = "Consider streaming (StreamingEnabled), merging meshes, or culling distant detail.",
		})
	end
	if metrics.unions > 2000 then
		table.insert(findings, {
			severity = "Medium",
			title = ("Many UnionOperations (%d)"):format(metrics.unions),
			advice = "Unions are costly to render. Convert static unions to MeshParts where possible.",
		})
	end

	return { findings = findings, metrics = metrics }
end

return PerformanceAnalyzer
