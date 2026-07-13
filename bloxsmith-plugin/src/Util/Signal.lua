
--[[ Signal.lua — tiny event implementation for decoupling services from UI. ]]
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handlers = self._handlers
	handlers[fn] = true
	return {
		Disconnect = function()
			handlers[fn] = nil
		end,
	}
end

function Signal:Fire(...)
	for fn in pairs(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal