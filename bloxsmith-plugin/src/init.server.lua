--[[
	Bloxsmith — init.server.lua
	Plugin bootstrap: creates the toolbar button + dock widget, instantiates the
	service layer, and mounts the UI. All heavy lifting lives in the modules under
	Services/ and UI/ to keep this entry point thin and maintainable.
]]
local Selection = game:GetService("Selection")

local Config = _R("Config")
local Log = _R("Util.Log")

-- Services
local AIService = _R("Services.AIService")
local ContextService = _R("Services.ContextService")
local ApplyService = _R("Services.ApplyService")
local SecurityScanner = _R("Services.SecurityScanner")
local PerformanceAnalyzer = _R("Services.PerformanceAnalyzer")
local CleanupService = _R("Services.CleanupService")
local ErrorMonitor = _R("Services.ErrorMonitor")
local HealthService = _R("Services.HealthService")

-- UI
local App = _R("UI.App")

Log.info(("v%s loading…"):format(Config.Version))

-- Toolbar + button
local toolbar = plugin:CreateToolbar("Bloxsmith")
local toggleButton = toolbar:CreateButton(
	"Bloxsmith",
	"Open the Bloxsmith AI copilot",
	"rbxasset://textures/ui/GuiImagePlaceholder.png"
)
toggleButton.ClickableWhenViewportHidden = true

-- Dock widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false, -- start closed
	false,
	420, -- default width
	560, -- default height
	340, -- min width
	400 -- min height
)
local widget = plugin:CreateDockWidgetPluginGui("BloxsmithMain", widgetInfo)
widget.Title = "Bloxsmith — AI Copilot"
widget.Name = "BloxsmithMain"

-- Instantiate service layer
local security = SecurityScanner.new()
local performance = PerformanceAnalyzer.new()
local cleanup = CleanupService.new()

local deps = {
	plugin = plugin,
	ai = AIService.new(plugin),
	context = ContextService.new(),
	security = security,
	performance = performance,
	cleanup = cleanup,
	errors = ErrorMonitor.new(),
	health = HealthService.new(security, performance, cleanup),
}
deps.apply = ApplyService.new(deps.context)

deps.errors:start()

-- Root gui frame inside the widget
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = Config and Color3.fromRGB(18, 18, 24)
root.BorderSizePixel = 0
root.Parent = widget

local app = App.new(deps)
app:mount(root)

-- Keep the selection strip live
Selection.SelectionChanged:Connect(function()
	pcall(function()
		app:refreshSelectionStrip()
	end)
end)

-- Toggle behavior
local function updateButton()
	toggleButton:SetActive(widget.Enabled)
end

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	updateButton()
end)
widget:GetPropertyChangedSignal("Enabled"):Connect(updateButton)
updateButton()

-- Clean shutdown
plugin.Unloading:Connect(function()
	pcall(function()
		app:saveCurrentConversation()
	end)
	deps.errors:stop()
	Log.info("unloaded.")
end)

Log.info("ready.")