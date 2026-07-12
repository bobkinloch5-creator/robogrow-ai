--[[
	App.lua
	The whole Bloxsmith interface: sidebar navigation, chat, tools, project
	analysis, health dashboard, error monitor and settings. Pure Instance-based
	UI (no external libs) built through the Create helper and themed via Theme.
]]
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Parser = require(script.Parent.Parent.Util.Parser)
local Config = require(script.Parent.Parent.Config)

local App = {}
App.__index = App

function App.new(deps)
	local self = setmetatable({}, App)
	self.deps = deps
	self.history = {} -- {role, content}
	self.mode = "chat"
	self.views = {}
	self.navButtons = {}
	self.busy = false
	return self
end

--========================================================================
-- Small UI primitives
--========================================================================
local C = Theme.Color

local function corner(radius)
	return Create("UICorner", { CornerRadius = radius or Theme.Radius })
end

local function pad(px)
	px = px or Theme.Pad
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	})
end

local function stroke(color)
	return Create("UIStroke", { Color = color or C.Border, Thickness = 1 })
end

local function button(text, props)
	props = props or {}
	local btn = Create("TextButton", {
		Text = text,
		Font = Theme.FontBold,
		TextSize = props.TextSize or 13,
		TextColor3 = props.TextColor3 or C.Text,
		BackgroundColor3 = props.BackgroundColor3 or C.Accent,
		AutoButtonColor = true,
		Size = props.Size or UDim2.new(1, 0, 0, 32),
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	}, { corner(UDim.new(0, 6)) })
	return btn
end

function App:toast(message, kind)
	local color = C.Info
	if kind == "success" then
		color = C.Success
	elseif kind == "warning" then
		color = C.Warning
	elseif kind == "error" then
		color = C.Error
	end
	local frame = Create("TextLabel", {
		Text = message,
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = C.Bg,
		BackgroundColor3 = color,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.toastHolder,
	}, { corner(UDim.new(0, 6)), pad(8) })
	task.delay(4, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

--========================================================================
-- Chat rendering
--========================================================================
function App:addBubble(role, text)
	local isUser = role == "user"
	local holder = Create("Frame", {
		BackgroundColor3 = isUser and C.UserBubble or C.AiBubble,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Border) })

	Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})

	Create("TextLabel", {
		Text = isUser and "You" or "Bloxsmith",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = isUser and C.Accent2 or C.Accent,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 0,
		Parent = holder,
	})

	-- Render the reply with code blocks stripped into their own panels.
	local blocks = Parser.extractBlocks(text)
	local prose = string.gsub(text, "```[^\n]*\n.-```", "\n[code block below]\n")

	Create("TextLabel", {
		Text = prose,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = C.Text,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
		Parent = holder,
	})

	-- "Insert all" shortcut when the reply contains multiple files.
	if #blocks > 1 then
		local insertAll = button(("＋ Insert all %d files into Studio"):format(#blocks), {
			LayoutOrder = 2,
			BackgroundColor3 = C.Success,
			TextColor3 = C.Bg,
		})
		insertAll.Parent = holder
		insertAll.Activated:Connect(function()
			local actions = {}
			for i, block in ipairs(blocks) do
				table.insert(actions, Parser.blockToAction(block, i))
			end
			local res = self.deps.apply:applyActions(actions, "Bloxsmith insert files")
			if res.ok then
				self:toast(("Inserted %d files (Ctrl+Z to undo)"):format(res.applied or #actions), "success")
			else
				self:toast(("Inserted %d of %d — check output."):format(res.applied or 0, #actions), "warning")
			end
		end)
	end

	for i, block in ipairs(blocks) do
		self:addCodeBlock(holder, block, i + 10)
	end


	self.chatScroll.CanvasPosition = Vector2.new(0, 1e6)
end

function App:addCodeBlock(parent, block, order)
	local panel = Create("Frame", {
		BackgroundColor3 = C.Bg,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	}, { corner(UDim.new(0, 6)), pad(8), stroke(C.AccentDim) })

	Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panel,
	})

	Create("TextLabel", {
		Text = string.format("%s  •  %s", block.class or "Script", block.path or "insert location auto-detected"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = C.TextDim,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 0,
		Parent = panel,
	})

	Create("TextLabel", {
		Text = block.source,
		Font = Theme.FontMono,
		TextSize = 12,
		TextColor3 = C.Success,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
		Parent = panel,
	})

	local insert = button("＋ Insert into Studio", { LayoutOrder = 2, BackgroundColor3 = C.AccentDim })
	insert.Parent = panel
	insert.Activated:Connect(function()
		local action = Parser.blockToAction(block, order)
		local res = self.deps.apply:applyActions({ action }, "Bloxsmith insert script")
		if res.ok then
			self:toast("Inserted " .. (action.name or "script") .. " (Ctrl+Z to undo)", "success")
		else
			self:toast("Insert failed: " .. (res.error or "unknown"), "error")
		end
	end)
end

--========================================================================
-- Backend call
--========================================================================
function App:send(promptText, mode)
	if self.busy then
		self:toast("Please wait for the current task to finish.", "warning")
		return
	end
	if not promptText or promptText == "" then
		return
	end
	self.busy = true
	self.sendBtn.Text = "…"

	self:addBubble("user", promptText)
	table.insert(self.history, { role = "user", content = promptText })

	local includeTree = mode ~= "chat"
	local context = self.deps.context:build(includeTree)

	task.spawn(function()
		local result = self.deps.ai:request({
			mode = mode or self.mode,
			messages = self.history,
			context = context,
		})
		self.busy = false
		self.sendBtn.Text = "Send"

		if result.ok then
			self:addBubble("assistant", result.reply)
			table.insert(self.history, { role = "assistant", content = result.reply })
			if result.actions then
				self:proposeAgentActions(result.actions)
			end
		else
			self:addBubble("assistant", "⚠️ " .. (result.error or "Request failed."))
			self:toast(result.error or "Request failed.", "error")
		end
	end)
end

function App:proposeAgentActions(actions)
	if type(actions) ~= "table" or #actions == 0 then
		return
	end
	local holder = Create("Frame", {
		BackgroundColor3 = C.PanelAlt,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Accent) })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = holder })
	Create("TextLabel", {
		Text = ("🤖 The agent proposes %d change(s). Apply?"):format(#actions),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = C.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = holder,
	})
	local approve = button("✓ Approve & Apply", { BackgroundColor3 = C.Success, TextColor3 = C.Bg })
	approve.Parent = holder
	approve.Activated:Connect(function()
		local res = self.deps.apply:applyActions(actions, "Bloxsmith agent task")
		if res.ok then
			self:toast("Applied " .. #(res.created or {}) .. " change(s). Ctrl+Z to undo.", "success")
		else
			self:toast("Some actions failed — check output.", "warning")
		end
		approve.Text = "Applied"
		approve.Active = false
	end)
end

--========================================================================
-- Views
--========================================================================
function App:buildChatView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = view })
	pad(0).Parent = view

	-- Selection context strip
	self.contextLabel = Create("TextLabel", {
		Text = "No selection",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = C.TextDim,
		BackgroundColor3 = C.Panel,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 0,
		Parent = view,
	}, { corner(UDim.new(0, 6)), pad(6) })

	-- Chat scroll
	self.chatScroll = Create("ScrollingFrame", {
		BackgroundColor3 = C.BgAlt,
		Size = UDim2.new(1, 0, 1, -110),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.Accent,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = view,
	}, { corner(UDim.new(0, 6)), pad(8) })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.chatScroll })

	-- Mode buttons row
	local modeRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2, Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = modeRow })
	local modes = { { "Chat", "chat" }, { "Generate", "generate_script" }, { "Fix", "fix_script" }, { "Explain", "explain_script" }, { "Optimize", "optimize_script" } }
	self.modeButtons = {}
	for _, m in ipairs(modes) do
		local b = button(m[1], { Size = UDim2.new(0, 78, 1, 0), BackgroundColor3 = C.Panel, TextSize = 11 })
		b.Parent = modeRow
		b.Activated:Connect(function()
			self:setMode(m[2])
		end)
		self.modeButtons[m[2]] = b
	end

	-- Input row
	local inputRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 3, Parent = view })
	self.input = Create("TextBox", {
		PlaceholderText = "Ask Bloxsmith or describe what to build…",
		Text = "",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = C.Text,
		PlaceholderColor3 = C.TextFaint,
		BackgroundColor3 = C.Panel,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ClearTextOnFocus = false,
		MultiLine = true,
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = inputRow,
	}, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })

	self.sendBtn = button("Send", { Size = UDim2.new(0, 62, 1, 0) })
	self.sendBtn.Position = UDim2.new(1, -62, 0, 0)
	self.sendBtn.Parent = inputRow
	self.sendBtn.Activated:Connect(function()
		local text = self.input.Text
		self.input.Text = ""
		self:send(text, self.mode)
	end)

	self.chatView = view
	self:setMode("chat")
end

function App:setMode(mode)
	self.mode = mode
	for m, b in pairs(self.modeButtons or {}) do
		b.BackgroundColor3 = (m == mode) and C.Accent or C.Panel
	end
end

-- Generic results list used by Analysis / Health.
function App:renderFindings(parent, findings, emptyMsg)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Frame") and child:GetAttribute("finding") then
			child:Destroy()
		end
	end
	if #findings == 0 then
		local ok = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent }, { corner(UDim.new(0, 6)), pad(8) })
		ok:SetAttribute("finding", true)
		Create("TextLabel", { Text = "✓ " .. (emptyMsg or "Nothing found. Looking good!"), Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Success, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = ok })
		return
	end
	for _, f in ipairs(findings) do
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = parent }, { corner(UDim.new(0, 6)), pad(8) })
		card:SetAttribute("finding", true)
		Create("UIListLayout", { Padding = UDim.new(0, 3), Parent = card })
		Create("UIStroke", { Color = Theme.severityColor(f.severity), Thickness = 1, Parent = card })
		Create("TextLabel", { Text = string.format("[%s] %s", string.upper(f.severity or "INFO"), f.title or ""), Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.severityColor(f.severity), BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
		if f.path then
			Create("TextLabel", { Text = f.path, Font = Theme.FontMono, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
		end
		Create("TextLabel", { Text = f.advice or "", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
	end
end

function App:buildAnalysisView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	local row = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = row })
	local sec = button("🛡 Security", { Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = C.Panel })
	local perf = button("⚡ Performance", { Size = UDim2.new(0, 110, 1, 0), BackgroundColor3 = C.Panel })
	local clean = button("🧹 Cleanup", { Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = C.Panel })
	sec.Parent, perf.Parent, clean.Parent = row, row, row

	local results = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = results })

	sec.Activated:Connect(function()
		self:renderFindings(results, self.deps.security:scan(), "No security issues detected.")
		self:toast("Security scan complete.", "success")
	end)
	perf.Activated:Connect(function()
		local r = self.deps.performance:analyze()
		self:renderFindings(results, r.findings, "No performance issues detected.")
		self:toast(("Perf: %d parts, %d scripts, %d unions."):format(r.metrics.parts, r.metrics.scripts, r.metrics.unions), "info")
	end)
	clean.Activated:Connect(function()
		self:renderFindings(results, self.deps.cleanup:scan(), "Project is tidy!")
		self:toast("Cleanup scan complete.", "success")
	end)
end

function App:buildHealthView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	local scoresRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 70), Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = scoresRow })

	local function scoreCard(title)
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(0.33, -4, 1, 0), Parent = scoresRow }, { corner(UDim.new(0, 8)), pad(6) })
		Create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), Parent = card })
		local num = Create("TextLabel", { Text = "–", Font = Theme.FontBold, TextSize = 26, TextColor3 = C.TextDim, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = card })
		Create("TextLabel", { Text = title, Font = Theme.Font, TextSize = 11, TextColor3 = C.TextDim, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Parent = card })
		return num
	end
	local secNum = scoreCard("Security")
	local perfNum = scoreCard("Performance")
	local orgNum = scoreCard("Organization")

	local computeBtn = button("Compute health scores", { Size = UDim2.new(1, 0, 0, 32) })
	computeBtn.Parent = view
	local recBtn = button("✨ Get AI recommendations", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.Accent2 })
	recBtn.Parent = view

	local results = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = results })

	computeBtn.Activated:Connect(function()
		local h = self.deps.health:compute()
		secNum.Text = tostring(h.security.score)
		secNum.TextColor3 = Theme.scoreColor(h.security.score)
		perfNum.Text = tostring(h.performance.score)
		perfNum.TextColor3 = Theme.scoreColor(h.performance.score)
		orgNum.Text = tostring(h.organization.score)
		orgNum.TextColor3 = Theme.scoreColor(h.organization.score)
		local all = {}
		for _, list in ipairs({ h.security.findings, h.performance.findings, h.organization.findings }) do
			for _, f in ipairs(list) do
				table.insert(all, f)
			end
		end
		self:renderFindings(results, all, "Excellent — no issues across the board!")
		self:toast("Health computed.", "success")
	end)

	recBtn.Activated:Connect(function()
		self:selectView("Chat")
		self:setMode("chat")
		self:send("Review my project and give prioritized recommendations for gameplay, monetization, retention and UX.", "recommend")
	end)
end

function App:buildErrorsView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	local row = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = row })
	local clearBtn = button("Clear", { Size = UDim2.new(0, 70, 1, 0), BackgroundColor3 = C.Panel })
	clearBtn.Parent = row

	local list = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -38), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = list })

	local function render()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		local errs = self.deps.errors:get()
		if #errs == 0 then
			Create("TextLabel", { Text = "No errors captured. Errors printed to Output will appear here.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundColor3 = C.Panel, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = list }, { corner(UDim.new(0, 6)), pad(8) }) })
			return
		end
		for _, e in ipairs(errs) do
			local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = list }, { corner(UDim.new(0, 6)), pad(8) })
			Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = card })
			Create("UIStroke", { Color = C.Error, Thickness = 1, Parent = card })
			Create("TextLabel", { Text = e.message, Font = Theme.FontMono, TextSize = 12, TextColor3 = C.Error, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card })
			local fix = button("🔧 Fix with AI", { Size = UDim2.new(0, 110, 0, 26), BackgroundColor3 = C.AccentDim, TextSize = 11 })
			fix.Parent = card
			fix.Activated:Connect(function()
				self:selectView("Chat")
				self:send("I got this Roblox error, explain the cause and how to fix it:\n" .. e.message, "chat")
			end)
		end
	end

	clearBtn.Activated:Connect(function()
		self.deps.errors:clear()
	end)
	self.deps.errors.Changed:Connect(function()
		if self.currentView == "Errors" then
			render()
		end
	end)
	self._renderErrors = render
end

function App:buildToolsView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = view })
	pad(0).Parent = view

	Create("TextLabel", { Text = "Quick actions — type a description, then run. Uses your current selection & project as context.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	local box = Create("TextBox", { PlaceholderText = "e.g. a wave-based zombie survival shop with 6 weapons", Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, MultiLine = true, Size = UDim2.new(1, 0, 0, 56), Parent = view }, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })

	local tools = {
		{ "🎮 Generate game system", "generate_system", "Build a complete system for: " },
		{ "🖼 Generate UI", "generate_ui", "Create a polished UI for: " },
		{ "🤖 Run build agent", "agent", "Complete this task, propose actions to apply: " },
		{ "📄 Generate docs", "docs", "Write documentation for the selected script(s). Notes: " },
		{ "🛠 Fix selected script", "fix_script", "Fix the selected script. Notes: " },
		{ "⚡ Optimize selected script", "optimize_script", "Optimize the selected script. Notes: " },
	}
	for _, t in ipairs(tools) do
		local b = button(t[1], { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.Panel })
		b.Parent = view
		b.Activated:Connect(function()
			self:selectView("Chat")
			self:send(t[3] .. (box.Text ~= "" and box.Text or "(see selection)"), t[2])
			box.Text = ""
		end)
	end
end

function App:buildSettingsView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	Create("TextLabel", { Text = "Backend URL", Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Parent = view })
	local urlBox = Create("TextBox", { Text = self.deps.ai:getUrl(), Font = Theme.FontMono, TextSize = 12, TextColor3 = C.Text, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextWrapped = true, Size = UDim2.new(1, 0, 0, 50), Parent = view }, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local save = button("Save backend URL", { Size = UDim2.new(1, 0, 0, 32) })
	save.Parent = view
	save.Activated:Connect(function()
		self.deps.ai:setUrl(urlBox.Text)
		self:toast("Backend URL saved.", "success")
	end)

	Create("TextLabel", { Text = "The plugin never stores an AI key — it calls a secure backend that holds the provider credentials. Switch providers (Bedrock, etc.) on the backend without updating the plugin.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	Create("TextLabel", { Text = ("Bloxsmith v%s"):format(Config.Version), Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), Parent = view })
end

--========================================================================
-- Navigation + mount
--========================================================================
function App:selectView(name)
	self.currentView = name
	for viewName, frame in pairs(self.views) do
		frame.Visible = (viewName == name)
	end
	for viewName, btn in pairs(self.navButtons) do
		btn.BackgroundColor3 = (viewName == name) and C.Accent or C.Sidebar
		btn.TextColor3 = (viewName == name) and C.Text or C.TextDim
	end
	if name == "Errors" and self._renderErrors then
		self._renderErrors()
	end
end

function App:refreshSelectionStrip()
	if not self.contextLabel then
		return
	end
	local sel = self.deps.context:getSelection()
	if #sel == 0 then
		self.contextLabel.Text = "📍 No selection"
	else
		local names = {}
		for _, s in ipairs(sel) do
			table.insert(names, s.name .. " (" .. s.class .. ")")
		end
		self.contextLabel.Text = "📍 " .. table.concat(names, ", ")
	end
end

function App:mount(gui)
	gui.BackgroundColor3 = C.Bg
	Create("UICorner", { CornerRadius = UDim.new(0, 0), Parent = gui })

	-- Toast holder (overlay)
	self.toastHolder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 260, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -270, 0, 10),
		ZIndex = 50,
		Parent = gui,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = self.toastHolder })

	-- Sidebar
	local sidebar = Create("Frame", { BackgroundColor3 = C.Sidebar, Size = UDim2.new(0, 118, 1, 0), BorderSizePixel = 0, Parent = gui })
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = sidebar })
	pad(8).Parent = sidebar

	Create("TextLabel", { Text = "🔨 Bloxsmith", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 30), Parent = sidebar })

	-- Content area
	local content = Create("Frame", { BackgroundColor3 = C.Bg, Size = UDim2.new(1, -118, 1, 0), Position = UDim2.new(0, 118, 0, 0), BorderSizePixel = 0, Parent = gui }, { pad(10) })

	local nav = { "Chat", "Tools", "Analysis", "Health", "Errors", "Settings" }
	for _, name in ipairs(nav) do
		local b = button(name, { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.Sidebar, TextColor3 = C.TextDim })
		b.Parent = sidebar
		b.Activated:Connect(function()
			self:selectView(name)
		end)
		self.navButtons[name] = b

		local frame = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = content })
		self.views[name] = frame
	end

	self:buildChatView(self.views.Chat)
	self:buildToolsView(self.views.Tools)
	self:buildAnalysisView(self.views.Analysis)
	self:buildHealthView(self.views.Health)
	self:buildErrorsView(self.views.Errors)
	self:buildSettingsView(self.views.Settings)

	self:selectView("Chat")
	self:addBubble("assistant", "👋 **Welcome to Bloxsmith!** I can generate scripts, UIs and full game systems, fix & optimize code, scan for security and performance issues, and run multi-step build tasks — you approve every change. Select an object and ask me anything.")
end

return App
