--[[ Theme.lua — single source of truth for the dark UI palette & spacing. ]]
local Theme = {}

Theme.Color = {
	Bg = Color3.fromRGB(18, 18, 24),
	BgAlt = Color3.fromRGB(24, 24, 32),
	Panel = Color3.fromRGB(28, 28, 38),
	PanelAlt = Color3.fromRGB(34, 34, 46),
	Border = Color3.fromRGB(48, 48, 64),
	Sidebar = Color3.fromRGB(22, 22, 30),

	Text = Color3.fromRGB(238, 238, 246),
	TextDim = Color3.fromRGB(150, 150, 168),
	TextFaint = Color3.fromRGB(105, 105, 125),

	Accent = Color3.fromRGB(150, 80, 255),
	Accent2 = Color3.fromRGB(236, 72, 153),
	AccentDim = Color3.fromRGB(80, 50, 130),

	UserBubble = Color3.fromRGB(46, 40, 70),
	AiBubble = Color3.fromRGB(30, 30, 42),

	Success = Color3.fromRGB(74, 222, 128),
	Warning = Color3.fromRGB(250, 204, 21),
	Error = Color3.fromRGB(248, 113, 113),
	Info = Color3.fromRGB(96, 165, 250),
}

Theme.Font = Enum.Font.Gotham
Theme.FontBold = Enum.Font.GothamBold
Theme.FontMono = Enum.Font.Code

Theme.Pad = 10
Theme.Radius = UDim.new(0, 8)

function Theme.severityColor(sev)
	sev = string.lower(sev or "")
	if sev == "critical" or sev == "high" then
		return Theme.Color.Error
	elseif sev == "medium" then
		return Theme.Color.Warning
	elseif sev == "low" then
		return Theme.Color.Info
	end
	return Theme.Color.TextDim
end

function Theme.scoreColor(score)
	if score >= 80 then
		return Theme.Color.Success
	elseif score >= 55 then
		return Theme.Color.Warning
	end
	return Theme.Color.Error
end

return Theme
