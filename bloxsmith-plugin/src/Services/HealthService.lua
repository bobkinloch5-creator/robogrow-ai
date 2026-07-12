--[[
	HealthService.lua
	Aggregates the local analyzers into 0-100 scores for the health dashboard.
	Scores are heuristic and meant to guide attention, not to be absolute.
]]
local HealthService = {}
HealthService.__index = HealthService

function HealthService.new(security, performance, cleanup)
	return setmetatable({
		security = security,
		performance = performance,
		cleanup = cleanup,
	}, HealthService)
end

local WEIGHT = { Critical = 25, High = 15, Medium = 7, Low = 3 }

local function scoreFrom(findings)
	local score = 100
	for _, f in ipairs(findings) do
		score -= (WEIGHT[f.severity] or 3)
	end
	return math.clamp(score, 0, 100)
end

function HealthService:compute()
	local sec = self.security:scan()
	local perf = self.performance:analyze()
	local clean = self.cleanup:scan()

	return {
		security = { score = scoreFrom(sec), findings = sec },
		performance = { score = scoreFrom(perf.findings), findings = perf.findings, metrics = perf.metrics },
		organization = { score = scoreFrom(clean), findings = clean },
	}
end

return HealthService
