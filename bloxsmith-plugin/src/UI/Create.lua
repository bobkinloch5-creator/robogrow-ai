
--[[
	Create.lua — declarative Instance builder to keep UI code readable.
	Usage:
	  Create("TextButton", { Text = "Hi", Parent = frame }, {
	      Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
	  })
]]
local function Create(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

return Create
