--[[ Log.lua — namespaced, level-aware logging so output is easy to filter. ]]
local Log = {}

local PREFIX = "[Bloxsmith]"

function Log.info(...)
	print(PREFIX, ...)
end

function Log.warn(...)
	warn(PREFIX, ...)
end

function Log.error(...)
	warn(PREFIX, "ERROR:", ...)
end

-- Wrap a risky call, log failures, and return (ok, resultOrErr).
function Log.try(label, fn, ...)
	local ok, res = pcall(fn, ...)
	if not ok then
		Log.error(label, "->", res)
	end
	return ok, res
end

return Log
