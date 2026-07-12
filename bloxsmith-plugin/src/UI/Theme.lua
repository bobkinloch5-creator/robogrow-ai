--[[ Theme.lua — single source of truth for the premium dark UI palette & spacing.
	Matches the Bloxsmith brand: deep navy backgrounds with an electric blue → cyan accent. ]]
local Theme = {}

Theme.Color = {
	-- Deep navy surfaces (match the website's premium blue theme)
	Bg = Color3.fromRGB(9, 12, 22),
	BgAlt = Color3.fromRGB(13, 17, 30),
	Panel = Color3.fromRGB(18, 24, 40),
	PanelAlt = Color3.fromRGB(24, 32, 52),
	Border = Color3.fromRGB(38, 50, 78),
	Sidebar = Color3.fromRGB(11, 15, 27),

	Text = Color3.fromRGB(236, 242, 255),
	TextDim = Color3.fromRGB(148, 163, 196),
	TextFaint = Color3.fromRGB(96, 110, 142),

	-- Electric blue → cyan accent
	Accent = Color3.fromRGB(45, 121, 255),
	Accent2 = Color3.fromRGB(34, 211, 238),
	AccentDim = Color3.fromRGB(28, 64, 128),

	UserBubble = Color3.fromRGB(22, 45, 82),
	AiBubble = Color3.fromRGB(18, 24, 40),

	Success = Color3.fromRGB(52, 211, 153),
	Warning = Color3.fromRGB(251, 191, 36),
	Error = Color3.fromRGB(248, 113, 113),
	Info = Color3.fromRGB(56, 189, 248),
}

Theme.Font = Enum.Font.Gotham
Theme.FontMedium = Enum.Font.GothamMedium
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
