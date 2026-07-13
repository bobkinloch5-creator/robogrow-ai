
--[[
	ErrorMonitor.lua
	Captures Studio output errors via LogService and keeps a rolling buffer so the
	UI can surface them and offer AI-powered fixes.
]]
local LogService = game:GetService("LogService")
local Signal = _R("Util.Signal")

local ErrorMonitor = {}
ErrorMonitor.__index = ErrorMonitor

local MAX = 50

function ErrorMonitor.new()
	local self = setmetatable({}, ErrorMonitor)
	self.errors = {}
	self.Changed = Signal.new()
	self._conn = nil
	return self
end

function ErrorMonitor:start()
	if self._conn then
		return
	end
	self._conn = LogService.MessageOut:Connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageError then
			table.insert(self.errors, 1, { message = message, time = os.time() })
			while #self.errors > MAX do
				table.remove(self.errors)
			end
			self.Changed:Fire(self.errors)
		end
	end)
end

function ErrorMonitor:stop()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
end

function ErrorMonitor:clear()
	self.errors = {}
	self.Changed:Fire(self.errors)
end

function ErrorMonitor:get()
	return self.errors
end

return ErrorMonitor
end

