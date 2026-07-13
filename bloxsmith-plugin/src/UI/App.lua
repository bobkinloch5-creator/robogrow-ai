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
	local bg = props.BackgroundColor3 or C.Accent
	local btn = Create("TextButton", {
		Text = text,
		Font = Theme.FontBold,
		TextSize = props.TextSize or 13,
		TextColor3 = props.TextColor3 or C.Text,
		BackgroundColor3 = bg,
		AutoButtonColor = true,
		Size = props.Size or UDim2.new(1, 0, 0, 32),
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	}, { corner(UDim.new(0, 6)) })
	-- Premium blue → cyan gradient on primary (accent) buttons.
	if bg == C.Accent then
		Create("UIGradient", {
			Color = ColorSequence.new(C.Accent, C.Accent2),
			Rotation = 90,
			Parent = btn,
		})
	end
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

	-- Pull the AI's thinking/plan into its own collapsible panel (assistant only).
	local workingText = text
	if not isUser then
		local thinking, cleaned = Parser.extractThinking(text)
		workingText = cleaned
		if thinking and thinking ~= "" then
			self:addThinkingPanel(holder, thinking, 1)
		end
	end

	-- Render the reply with code blocks stripped into their own panels.
	local blocks = Parser.extractBlocks(workingText)
	local prose = string.gsub(workingText, "```[^\n]*\n.-```", "\n〔 code block below 〕\n")
	prose = prose:gsub("^%s+", ""):gsub("%s+$", "")

	if prose ~= "" then
		Create("TextLabel", {
			Text = Parser.toRichText(prose),
			RichText = true,
			Font = Theme.Font,
			TextSize = 13,
			TextColor3 = C.Text,
			BackgroundTransparency = 1,
			TextWrapped = true,
			LineHeight = 1.08,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2,
			Parent = holder,
		})
	end

	-- "Insert all" shortcut when the reply contains multiple files.
	if #blocks > 1 then
		local insertAll = button(("＋ Insert all %d files into Studio"):format(#blocks), {
			LayoutOrder = 3,
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

-- Collapsible "💭 Thinking" panel showing the AI's plan/reasoning.
function App:addThinkingPanel(parent, thinking, order)
	local panel = Create("Frame", {
		BackgroundColor3 = C.PanelAlt,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 1,
		Parent = parent,
	}, { corner(UDim.new(0, 6)), pad(8), stroke(C.Accent2) })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	local expanded = false
	local header = Create("TextButton", {
		Text = "💭 Thinking  ▸",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = C.Accent2,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 0,
		Parent = panel,
	})

	local body = Create("TextLabel", {
		Text = Parser.toRichText(thinking),
		RichText = true,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = C.TextDim,
		BackgroundTransparency = 1,
		TextWrapped = true,
		LineHeight = 1.08,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		LayoutOrder = 1,
		Parent = panel,
	})

	header.Activated:Connect(function()
		expanded = not expanded
		body.Visible = expanded
		header.Text = expanded and "💭 Thinking  ▾" or "💭 Thinking  ▸"
	end)
end

-- Live animated "thinking" indicator shown while a request is in flight.
function App:startThinking()
	local holder = Create("Frame", {
		BackgroundColor3 = C.AiBubble,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Accent2) })
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = holder })
	Create("TextLabel", {
		Text = "Bloxsmith", Font = Theme.FontBold, TextSize = 11, TextColor3 = C.Accent,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14), Parent = holder,
	})
	local status = Create("TextLabel", {
		Text = "💭 Thinking.", Font = Theme.Font, TextSize = 13, TextColor3 = C.TextDim,
		BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = holder,
	})

	-- Cancel button — lets the user abandon a long build. The network call can't
	-- be aborted mid-flight, so cancelling flags the handle so its result is
	-- discarded and the UI is freed immediately.
	local handle = { cancelled = false }
	local cancelBtn = button("✕ Cancel", { Size = UDim2.new(0, 78, 0, 22), BackgroundColor3 = C.Panel, TextSize = 11 })
	cancelBtn.Parent = holder

	self.chatScroll.CanvasPosition = Vector2.new(0, 1e6)

	local phases = {
		"💭 Understanding your request",
		"🧭 Planning the build",
		"🧩 Designing the structure",
		"⌨️ Writing Luau",
		"🔌 Wiring it all up",
		"✨ Polishing the result",
	}
	local running = true
	local startedAt = os.clock()
	task.spawn(function()
		local i, dots = 1, 1
		while running and holder.Parent do
			local secs = math.floor(os.clock() - startedAt)
			status.Text = phases[i] .. string.rep(".", dots) .. ("   ⏱ %ds"):format(secs)
			dots += 1
			if dots > 3 then
				dots = 1
				i = (i % #phases) + 1
			end
			task.wait(0.5)
		end
	end)

	handle.stop = function()
		running = false
		if holder and holder.Parent then
			holder:Destroy()
		end
	end

	cancelBtn.Activated:Connect(function()
		handle.cancelled = true
		handle.stop()
		self.busy = false
		self.sendBtn.Text = "Send"
		self:toast("Build cancelled.", "warning")
	end)

	return handle
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
		insert.Text = "Inserting…"
		local action = Parser.blockToAction(block, order)
		local res = self.deps.apply:applyActions({ action }, "Bloxsmith insert script")
		if res.ok and (res.applied or 0) > 0 then
			local where = action.path or "ServerScriptService"
			self:toast(("✓ Added '%s' to %s (open Explorer to see it). Ctrl+Z to undo."):format(action.name or "script", where), "success")
			insert.Text = "✓ Inserted into " .. where
		else
			self:toast("Insert failed: " .. (res.error or "unknown"), "error")
			insert.Text = "＋ Retry insert"
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

	-- Dismiss the onboarding card on first message.
	if self._welcomeCard then
		self._welcomeCard:Destroy()
		self._welcomeCard = nil
	end

	self:addBubble("user", promptText)
	table.insert(self.history, { role = "user", content = promptText })


	local includeTree = mode ~= "chat"
	local context = self.deps.context:build(includeTree)

	-- Show the live thinking indicator while the request is in flight.
	local thinkingHandle = self:startThinking()

	task.spawn(function()
		local result = self.deps.ai:request({
			mode = mode or self.mode,
			messages = self.history,
			context = context,
		})
		-- If the user cancelled while the request was in flight, discard the
		-- result entirely — the UI was already freed by the cancel handler.
		if thinkingHandle.cancelled then
			return
		end
		thinkingHandle.stop()
		self.busy = false
		self.sendBtn.Text = "Send"

		if result.ok then
			local reply = result.reply
			if type(reply) ~= "string" or reply == "" then
				reply = "I prepared changes for your game. Review and approve them below."
			end
			self:addBubble("assistant", reply)
			table.insert(self.history, { role = "assistant", content = reply })
			local actions = result.actions or Parser.extractActions(reply)
			if actions then
				self:proposeAgentActions(actions)
			end
		else
			self:addBubble("assistant", "⚠️ " .. (result.error or "Request failed."))
			self:toast(result.error or "Request failed.", "error")
		end
		-- Persist the running conversation so Bloxsmith remembers it across
		-- plugin reloads / Studio restarts.
		self:saveActiveSession()
	end)
end

-- Human-readable one-line summary of a single agent action, for the plan checklist.
local function describeAction(a)
	local kind = a.action or "change"
	local name = a.name or a.target or a.class or ""
	local map = {
		create_script = "Create script",
		replace_script = "Replace script",
		create_folder = "Create folder",
		create_instance = "Create " .. tostring(a.class or "instance"),
		set_property = "Set " .. tostring(a.property or "property"),
		rename_instance = "Rename",
		delete_instance = "Delete",
		move_instance = "Move",
		insert_asset = "Insert asset",
	}
	local label = map[kind] or tostring(kind)
	if name ~= "" then
		label = label .. "  ·  " .. tostring(name)
	end
	if #label > 60 then
		label = label:sub(1, 57) .. "…"
	end
	return label
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
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	Create("TextLabel", {
		Text = ("🤖 Build plan — %d step(s). Approve to apply:"):format(#actions),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = C.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 0,
		Parent = holder,
	})

	-- Live checklist: one row per action, ticked off as the build applies.
	local rows = {}
	for i, a in ipairs(actions) do
		rows[i] = Create("TextLabel", {
			Text = ("☐  %d. %s"):format(i, describeAction(a)),
			Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim,
			BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = i, Parent = holder,
		})
	end

	local approve = button("✓ Approve & Apply", { BackgroundColor3 = C.Success, TextColor3 = C.Bg, LayoutOrder = #actions + 1 })
	approve.Parent = holder
	approve.Activated:Connect(function()
		approve.Text = "Applying…"
		approve.Active = false
		local res = self.deps.apply:applyActions(actions, "Bloxsmith agent task")
		local results = res.results or {}
		for i, row in ipairs(rows) do
			local r = results[i]
			if r and r.ok then
				row.Text = ("✅  %d. %s"):format(i, describeAction(actions[i]))
				row.TextColor3 = C.Success
			elseif r then
				row.Text = ("❌  %d. %s"):format(i, describeAction(actions[i]))
				row.TextColor3 = C.Error
			end
		end
		if res.ok then
			self:toast(("Applied %d step(s). Ctrl+Z to undo."):format(#(res.created or {})), "success")
			approve.Text = "✓ Applied"
		else
			self:toast(("Applied %d of %d — check output."):format(res.applied or 0, #actions), "warning")
			approve.Text = "Applied with issues"
		end
		-- Auto-fix loop: if the build produced runtime errors, offer a one-tap fix.
		self:offerAutoFix()
	end)
end

-- If a runtime error appeared right after a build, surface a one-tap AI fix.
function App:offerAutoFix()
	local errs = self.deps.errors and self.deps.errors:get()
	if type(errs) ~= "table" or #errs == 0 then
		return
	end
	local latest = errs[1]
	if not latest or (os.time() - (latest.time or 0)) > 20 then
		return
	end
	local holder = Create("Frame", {
		BackgroundColor3 = C.PanelAlt, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.Error) })
	Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = holder })
	Create("TextLabel", {
		Text = "⚠️ An error appeared in Output. Want me to fix it?",
		Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Warning, BackgroundTransparency = 1,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), Parent = holder,
	})
	local fix = button("🔧 Fix this error with AI", { BackgroundColor3 = C.AccentDim })
	fix.Parent = holder
	fix.Activated:Connect(function()
		fix.Active = false
		fix.Text = "Fixing…"
		self:send("This error appeared after the last build. Diagnose the cause and fix it:\n" .. tostring(latest.message), "fix_script")
	end)
end

-- Quick-action helper: send the most recent captured error to the AI to fix.
function App:fixLatestError()
	local errs = self.deps.errors and self.deps.errors:get()
	if type(errs) ~= "table" or #errs == 0 then
		self:toast("No errors captured yet. Run your game to reproduce one.", "info")
		return
	end
	self:send("Fix this Roblox error — explain the cause and apply a fix:\n" .. tostring(errs[1].message), "fix_script")
end

--========================================================================
-- Views
--========================================================================
function App:buildChatView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = view })
	pad(0).Parent = view

	-- Header row: Clear + History
	local headerRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 0, Parent = view })
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = headerRow,
	})
	local historyBtn = button("🕘 History", { Size = UDim2.new(0, 92, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	historyBtn.Parent = headerRow
	historyBtn.Activated:Connect(function()
		self:toggleHistoryPanel(true)
	end)
	local clearBtn = button("🗑 Clear", { Size = UDim2.new(0, 80, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	clearBtn.Parent = headerRow
	clearBtn.Activated:Connect(function()
		self:clearChat()
	end)

	-- Selection context strip
	self.contextLabel = Create("TextLabel", {
		Text = "No selection",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = C.TextDim,
		BackgroundColor3 = C.Panel,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 1,
		Parent = view,
	}, { corner(UDim.new(0, 6)), pad(6) })

	-- Selection-aware quick edits — instant, undoable tweaks to whatever is
	-- selected in Studio (no AI round-trip needed).
	local selRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2, Parent = view })
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = selRow,
	})
	local selEdits = {
		{ "➕ Bigger", "scale", 1.25 },
		{ "➖ Smaller", "scale", 0.8 },
		{ "⧉ Duplicate", "duplicate" },
		{ "⚓ Anchor", "anchor", true },
		{ "🗑 Delete", "delete" },
	}
	for _, e in ipairs(selEdits) do
		local chip = button(e[1], { Size = UDim2.new(0, 78, 1, 0), BackgroundColor3 = C.Panel, TextSize = 11 })
		chip.Parent = selRow
		chip.Activated:Connect(function()
			local res = self.deps.apply:editSelection(e[2], e[3])
			if res.ok then
				self:toast(("Edited %d object(s). Ctrl+Z to undo."):format(res.count or 1), "success")
				self:refreshSelectionStrip()
			else
				self:toast(res.error or "Selection edit failed.", "warning")
			end
		end)
	end

	-- Persistent prompt quick-actions — one-tap common builds + auto-fix.
	local quickRow = Create("ScrollingFrame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26),
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
		ScrollingDirection = Enum.ScrollingDirection.X, BorderSizePixel = 0,
		LayoutOrder = 3, Parent = view,
	})
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = quickRow })
	local quickActions = {
		{ "🔧 Fix latest error", "__fix__" },
		{ "🏛 Build a lobby", "Build a polished game lobby with a spawn area, decorated environment and a play button UI.", "generate_system" },
		{ "🏆 Leaderboard", "Add a global leaderboard using OrderedDataStore that tracks player wins.", "generate_system" },
		{ "🌗 Day-night cycle", "Add a smooth continuous day-night cycle that animates Lighting.ClockTime.", "generate_system" },
		{ "🚪 Teleport pads", "Create two linked teleport pads that move the player between them on touch.", "generate_system" },
		{ "💰 Coin pickups", "Add collectable coins that give the player points and respawn after a short delay.", "generate_system" },
	}
	for i, qa in ipairs(quickActions) do
		local chip = button(qa[1], { Size = UDim2.new(0, 128, 1, 0), BackgroundColor3 = C.PanelAlt, TextSize = 11 })
		chip.LayoutOrder = i
		chip.Parent = quickRow
		chip.Activated:Connect(function()
			if qa[2] == "__fix__" then
				self:fixLatestError()
			else
				self:send(qa[2], qa[3])
			end
		end)
	end

	-- Chat scroll
	self.chatScroll = Create("ScrollingFrame", {
		BackgroundColor3 = C.BgAlt,
		Size = UDim2.new(1, 0, 1, -218),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.Accent,
		BorderSizePixel = 0,
		LayoutOrder = 4,
		Parent = view,
	}, { corner(UDim.new(0, 6)), pad(8) })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.chatScroll })

	-- Mode buttons row
	local modeRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 5, Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = modeRow })
	local modes = { { "Chat", "chat" }, { "Generate", "agent" }, { "Fix", "fix_script" }, { "Explain", "explain_script" }, { "Optimize", "optimize_script" } }
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
	local inputRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 6, Parent = view })
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
	self:buildHistoryPanel(parent)
	self:setMode("chat")
	self:showWelcome()
end

--========================================================================
-- Chat history (persisted via plugin settings) + clear
--========================================================================
local HISTORY_KEY = "Bloxsmith_ChatHistory"
local ACTIVE_KEY = "Bloxsmith_ActiveSession"

function App:loadHistoryStore()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(HISTORY_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end

function App:saveHistoryStore(list)
	pcall(function()
		self.deps.plugin:SetSetting(HISTORY_KEY, list)
	end)
end

-- Persist the *current* conversation so Bloxsmith remembers context between
-- plugin reloads and Studio restarts (long-term memory).
function App:saveActiveSession()
	pcall(function()
		local snapshot = {}
		for _, m in ipairs(self.history or {}) do
			table.insert(snapshot, { role = m.role, content = m.content })
		end
		self.deps.plugin:SetSetting(ACTIVE_KEY, snapshot)
	end)
end

-- Restore the last active conversation on startup so the AI keeps its memory.
function App:restoreActiveSession()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(ACTIVE_KEY)
	end)
	if not (ok and type(data) == "table" and #data > 0) then
		return false
	end
	self.history = {}
	for _, m in ipairs(data) do
		if type(m) == "table" and m.role and m.content then
			table.insert(self.history, { role = m.role, content = m.content })
		end
	end
	if #self.history == 0 then
		return false
	end
	if self._welcomeCard then
		self._welcomeCard:Destroy()
		self._welcomeCard = nil
	end
	self:clearChatBubbles()
	for _, m in ipairs(self.history) do
		self:addBubble(m.role, m.content)
	end
	return true
end


-- Save the current conversation into persistent history (deduped, capped).
function App:saveCurrentConversation()
	if not self.history or #self.history == 0 then
		return
	end
	local list = self:loadHistoryStore()

	local title = "Conversation"
	for _, m in ipairs(self.history) do
		if m.role == "user" and m.content ~= "" then
			title = m.content
			break
		end
	end
	if #title > 60 then
		title = title:sub(1, 57) .. "…"
	end

	-- Skip if identical to the most recent saved conversation.
	local top = list[1]
	if top and top.messages and #top.messages == #self.history then
		local a = top.messages[#top.messages]
		local b = self.history[#self.history]
		if a and b and a.content == b.content then
			return
		end
	end

	local snapshot = {}
	for _, m in ipairs(self.history) do
		table.insert(snapshot, { role = m.role, content = m.content })
	end

	table.insert(list, 1, { title = title, time = os.time(), messages = snapshot })
	while #list > 25 do
		table.remove(list)
	end
	self:saveHistoryStore(list)
end

function App:clearChatBubbles()
	for _, ch in ipairs(self.chatScroll:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
			ch:Destroy()
		end
	end
	self._welcomeCard = nil
end

-- Clear button: archive the current chat, then reset to a fresh conversation.
function App:clearChat()
	if self.busy then
		self:toast("Please wait for the current task to finish.", "warning")
		return
	end
	self:saveCurrentConversation()
	self.history = {}
	self:saveActiveSession()
	self:clearChatBubbles()
	self:showWelcome()
	self:toast("Chat cleared — saved to History.", "success")
end

function App:loadConversation(convo)
	self.history = {}
	for _, m in ipairs(convo.messages or {}) do
		table.insert(self.history, { role = m.role, content = m.content })
	end
	self:clearChatBubbles()
	for _, m in ipairs(self.history) do
		self:addBubble(m.role, m.content)
	end
	self:saveActiveSession()
	self:toggleHistoryPanel(false)
	self:toast("Conversation loaded.", "success")
end

function App:toggleHistoryPanel(show)
	if not self.historyPanel then
		return
	end
	if show == nil then
		show = not self.historyPanel.Visible
	end
	if show then
		self:saveCurrentConversation()
		self:refreshHistoryPanel()
	end
	self.historyPanel.Visible = show
	if self.chatView then
		self.chatView.Visible = not show
	end
end

function App:buildHistoryPanel(parent)
	local panel = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	pad(0).Parent = panel
	self.historyPanel = panel

	-- Top bar
	local top = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 0, Parent = panel })
	local back = button("← Back", { Size = UDim2.new(0, 76, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	back.Parent = top
	back.Activated:Connect(function()
		self:toggleHistoryPanel(false)
	end)
	Create("TextLabel", {
		Text = "🕘 Chat History", Font = Theme.FontBold, TextSize = 14, TextColor3 = C.Text,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 84, 0, 0), Size = UDim2.new(1, -170, 1, 0), Parent = top,
	})
	local clearAll = button("Clear all", { Size = UDim2.new(0, 78, 1, 0), BackgroundColor3 = C.Panel, TextSize = 12 })
	clearAll.Position = UDim2.new(1, -78, 0, 0)
	clearAll.Parent = top
	clearAll.Activated:Connect(function()
		self:saveHistoryStore({})
		self:refreshHistoryPanel()
		self:toast("History cleared.", "success")
	end)

	-- Scrollable list of saved conversations
	self.historyList = Create("ScrollingFrame", {
		BackgroundColor3 = C.BgAlt, Size = UDim2.new(1, 0, 1, -38),
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent, BorderSizePixel = 0,
		LayoutOrder = 1, Parent = panel,
	}, { corner(UDim.new(0, 6)), pad(8) })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.historyList })
end

function App:refreshHistoryPanel()
	if not self.historyList then
		return
	end
	for _, ch in ipairs(self.historyList:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
			ch:Destroy()
		end
	end

	local list = self:loadHistoryStore()
	if #list == 0 then
		Create("TextLabel", {
			Text = "No saved conversations yet.\nCleared chats are saved here automatically.",
			Font = Theme.Font, TextSize = 13, TextColor3 = C.TextDim, BackgroundTransparency = 1,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 60), Parent = self.historyList,
		})
		return
	end

	for i, convo in ipairs(list) do
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 54), LayoutOrder = i, Parent = self.historyList }, { corner(UDim.new(0, 6)), stroke(C.Border) })

		local openBtn = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, 0), Parent = card })
		Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), Parent = openBtn })
		Create("TextLabel", {
			Text = convo.title or "Conversation", Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, 0, 0, 18), Parent = openBtn,
		})
		local meta = ("%s · %d messages"):format(os.date("%b %d, %H:%M", convo.time or 0), #(convo.messages or {}))
		Create("TextLabel", {
			Text = meta, Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 14), Parent = openBtn,
		})
		openBtn.Activated:Connect(function()
			self:loadConversation(convo)
		end)

		local del = button("✕", { Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = C.PanelAlt, TextSize = 13 })
		del.Position = UDim2.new(1, -30, 0.5, -13)
		del.Parent = card
		del.Activated:Connect(function()
			local store = self:loadHistoryStore()
			table.remove(store, i)
			self:saveHistoryStore(store)
			self:refreshHistoryPanel()
		end)
	end
end


-- Friendly onboarding card with one-click starter prompts (empty chat only).
function App:showWelcome()
	if not self.chatScroll then
		return
	end
	local card = Create("Frame", {
		BackgroundColor3 = C.Panel,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.chatScroll,
	}, { corner(UDim.new(0, 8)), pad(10), stroke(C.AccentDim) })
	self._welcomeCard = card
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	Create("TextLabel", {
		Text = "🔨 Welcome to Bloxsmith",
		Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = card,
	})
	Create("TextLabel", {
		Text = "Your AI copilot for Roblox. Describe what you want to build, or try one of these:",
		Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim,
		BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1, Parent = card,
	})

	local starters = {
		{ "🎒 Build an inventory system", "Build a complete server-authoritative inventory system with a client UI.", "generate_system" },
		{ "🛒 Create a shop with 5 items", "Create a shop system with 5 purchasable items and a polished UI.", "generate_system" },
		{ "🏆 Add a global leaderboard", "Add a global leaderboard using OrderedDataStore that tracks player wins.", "generate_system" },
		{ "⚔️ Combat system with weapons", "Build a server-authoritative melee combat system with a sword tool.", "generate_system" },
		{ "🚪 Explain the selected script", "Explain what the selected script does and how it works.", "explain_script" },
	}
	for i, s in ipairs(starters) do
		local chip = button(s[1], { LayoutOrder = i + 1, BackgroundColor3 = C.PanelAlt, TextSize = 12 })
		chip.Parent = card
		chip.Activated:Connect(function()
			self:send(s[2], s[3])
		end)
	end
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

	-- Prompt presets — save the current description and re-run it later.
	local savePreset = button("💾 Save prompt as preset", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.PanelAlt, TextSize = 12 })
	savePreset.Parent = view
	local presetHolder = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = presetHolder })
	local function refreshPresets()
		for _, c in ipairs(presetHolder:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		local presets = self:loadPromptPresets()
		if #presets == 0 then return end
		Create("TextLabel", { Text = "⭐ Saved presets (tap to load, ✕ to remove)", Font = Theme.FontBold, TextSize = 11, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0, Parent = presetHolder })
		for i, p in ipairs(presets) do
			local rowf = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, Parent = presetHolder }, { corner(UDim.new(0, 6)), stroke(C.Border) })
			local load = Create("TextButton", { Text = "  " .. p, Font = Theme.Font, TextSize = 12, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -32, 1, 0), Parent = rowf })
			load.Activated:Connect(function()
				box.Text = p
				self:toast("Preset loaded into the box.", "success")
			end)
			local del = button("✕", { Size = UDim2.new(0, 26, 0, 24), BackgroundColor3 = C.PanelAlt, TextSize = 12 })
			del.Position = UDim2.new(1, -28, 0.5, -12)
			del.Parent = rowf
			del.Activated:Connect(function()
				local list = self:loadPromptPresets()
				table.remove(list, i)
				self:savePromptPresets(list)
				refreshPresets()
			end)
		end
	end
	savePreset.Activated:Connect(function()
		local txt = (box.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if txt == "" then
			self:toast("Type a description first.", "warning")
			return
		end
		local list = self:loadPromptPresets()
		table.insert(list, 1, txt)
		while #list > 15 do
			table.remove(list)
		end
		self:savePromptPresets(list)
		refreshPresets()
		self:toast("Preset saved.", "success")
	end)
	refreshPresets()
end

-- Prompt presets storage (persisted via plugin settings).
local PROMPT_PRESETS_KEY = "Bloxsmith_PromptPresets"
function App:loadPromptPresets()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(PROMPT_PRESETS_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end
function App:savePromptPresets(list)
	pcall(function()
		self.deps.plugin:SetSetting(PROMPT_PRESETS_KEY, list)
	end)
end

--========================================================================
-- Toolbox (Creator Store free-model search + insert)
--========================================================================
function App:buildToolboxView(parent)
	local view = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = view })
	pad(0).Parent = view

	Create("TextLabel", {
		Text = "🧰 Search the Roblox Toolbox for free models and insert them straight into your game.",
		Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 0, Parent = view,
	})

	-- Search row
	local searchRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1, Parent = view })
	local searchBox = Create("TextBox", {
		PlaceholderText = "Search models… e.g. medieval house, sports car, tree",
		Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint,
		BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		Size = UDim2.new(1, -74, 1, 0), Parent = searchRow,
	}, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local searchBtn = button("Search", { Size = UDim2.new(0, 66, 1, 0) })
	searchBtn.Position = UDim2.new(1, -66, 0, 0)
	searchBtn.Parent = searchRow

	-- Category filter chips — narrow searches to a kind of asset.
	local currentCategory = ""
	local categoryRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 2, Parent = view })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = categoryRow })
	local categories = {
		{ "All", "" },
		{ "Models", "model" },
		{ "Vehicles", "vehicle" },
		{ "Buildings", "building" },
		{ "Nature", "tree nature" },
		{ "Weapons", "weapon" },
	}
	local catButtons = {}
	local function setCategory(value, btn)
		currentCategory = value
		for _, cb in ipairs(catButtons) do
			cb.BackgroundColor3 = (cb == btn) and C.Accent or C.Panel
		end
	end
	for _, c in ipairs(categories) do
		local cb = button(c[1], { Size = UDim2.new(0, 66, 1, 0), BackgroundColor3 = (c[2] == "") and C.Accent or C.Panel, TextSize = 11 })
		cb.Parent = categoryRow
		table.insert(catButtons, cb)
		cb.Activated:Connect(function()
			setCategory(c[2], cb)
		end)
	end

	-- Insert-by-ID row (reliable fallback)
	local idRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 3, Parent = view })
	local idBox = Create("TextBox", {
		PlaceholderText = "…or paste a model Asset ID", Text = "", Font = Theme.FontMono, TextSize = 12,
		TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint, BackgroundColor3 = C.Panel,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		Size = UDim2.new(1, -74, 1, 0), Parent = idRow,
	}, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local idBtn = button("Insert", { Size = UDim2.new(0, 66, 1, 0), BackgroundColor3 = C.Success, TextColor3 = C.Bg })
	idBtn.Position = UDim2.new(1, -66, 0, 0)
	idBtn.Parent = idRow

	-- Favorites + recently inserted strips — one-click re-insert of saved models.
	local recentsHolder = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Parent = view })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = recentsHolder })

	-- Bulk insert row — drop every current search result at once.
	local lastResults = {}
	local bulkRow = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 5, Parent = view })
	local bulkBtn = button("＋ Insert all results", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.AccentDim, TextSize = 12 })
	bulkBtn.Visible = false
	bulkBtn.Parent = bulkRow
	local function updateBulk()
		if #lastResults > 0 then
			bulkRow.Size = UDim2.new(1, 0, 0, 28)
			bulkBtn.Visible = true
			bulkBtn.Text = ("＋ Insert all %d results"):format(#lastResults)
		else
			bulkRow.Size = UDim2.new(1, 0, 0, 0)
			bulkBtn.Visible = false
		end
	end

	-- Results scroll
	local results = Create("ScrollingFrame", {
		BackgroundColor3 = C.BgAlt, Size = UDim2.new(1, 0, 1, -190), CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = C.Accent,
		BorderSizePixel = 0, LayoutOrder = 6, Parent = view,
	}, { corner(UDim.new(0, 6)), pad(8) })
	local grid = Create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, 202), CellPadding = UDim2.new(0, 8, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = results,
	})

	-- Render a horizontal chip strip of saved models (favorites / recents).
	local function makeStrip(title, items, order, removeFn)
		local wrap = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = recentsHolder })
		Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap })
		Create("TextLabel", {
			Text = title, Font = Theme.FontBold, TextSize = 11, TextColor3 = C.TextDim,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0, Parent = wrap,
		})
		local strip = Create("ScrollingFrame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
			ScrollingDirection = Enum.ScrollingDirection.X, BorderSizePixel = 0, LayoutOrder = 1, Parent = wrap,
		})
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = strip })
		for i, item in ipairs(items) do
			local chip = button("＋ " .. (item.name or ("Asset " .. tostring(item.id))), { Size = UDim2.new(0, 130, 1, 0), BackgroundColor3 = C.Panel, TextSize = 11 })
			chip.LayoutOrder = i
			chip.Parent = strip
			chip.Activated:Connect(function()
				chip.Text = "Inserting…"
				task.spawn(function()
					local res = self.deps.apply:insertAsset(item.id, item.name)
					if res.ok then
						self:toast(("Re-inserted '%s' — Ctrl+Z to undo."):format(item.name or "model"), "success")
						chip.Text = "✓ Inserted"
					else
						self:toast(res.error or "Insert failed.", "error")
						chip.Text = "＋ Retry"
					end
				end)
			end)
			if removeFn then
				local x = button("✕", { Size = UDim2.new(0, 22, 1, 0), BackgroundColor3 = C.PanelAlt, TextSize = 11 })
				x.LayoutOrder = i
				x.Parent = strip
				x.Activated:Connect(function()
					removeFn(item.id)
				end)
			end
		end
	end

	-- Render favorites first, then recently inserted, from persisted storage.
	local refreshRecents
	refreshRecents = function()
		for _, c in ipairs(recentsHolder:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		local favs = self:loadToolboxFavorites()
		if #favs > 0 then
			makeStrip("⭐ Favorites", favs, 0, function(id)
				self:removeToolboxFavorite(id)
				refreshRecents()
			end)
		end
		local recents = self:loadToolboxRecents()
		if #recents > 0 then
			makeStrip("🕘 Recently inserted", recents, 1)
		end
	end
	self._refreshToolboxRecents = refreshRecents
	refreshRecents()



	local function clearResults()
		for _, c in ipairs(results:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
	end

	local function status(msg, kind)
		clearResults()
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = results }, { corner(UDim.new(0, 6)), pad(10) })
		-- Make the status span the full width by clearing grid influence.
		Create("TextLabel", {
			Text = msg, Font = Theme.Font, TextSize = 12,
			TextColor3 = kind == "error" and C.Error or C.TextDim, BackgroundTransparency = 1,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0), Parent = card,
		})
	end

	local function renderResults(items)
		clearResults()
		lastResults = items or {}
		updateBulk()
		if #items == 0 then
			status("No models found. Try different keywords.")
			return
		end
		for i, item in ipairs(items) do
			local card = Create("Frame", { BackgroundColor3 = C.Panel, LayoutOrder = i, Parent = results }, { corner(UDim.new(0, 8)), pad(6), stroke(C.Border) })
			Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
			-- Use Roblox's native thumbnail endpoint so the REAL model image renders
			-- inside Studio. ImageLabel cannot load raw CDN https URLs, but rbxthumb:// is
			-- resolved natively by the engine from the asset id.
			local thumb = item.id and ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(item.id) or (item.thumbnail or "")
			local imgHolder = Create("Frame", {
				BackgroundColor3 = C.Bg, Size = UDim2.new(1, 0, 0, 78), LayoutOrder = 0, Parent = card,
			}, { corner(UDim.new(0, 6)) })
			Create("ImageLabel", {
				Image = thumb, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.new(1, 0, 1, 0), Parent = imgHolder,
			})

			Create("TextLabel", {
				Text = item.name or "Model", Font = Theme.FontBold, TextSize = 12, TextColor3 = C.Text,
				BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = card,
			})
			local insertBtn = button("＋ Insert", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.AccentDim, TextSize = 11, LayoutOrder = 2 })
			insertBtn.Parent = card
			insertBtn.Activated:Connect(function()
				insertBtn.Text = "Inserting…"
				task.spawn(function()
					local res = self.deps.apply:insertAsset(item.id, item.name)
					if res.ok then
						local msg = (res.results and res.results[1] and res.results[1].message)
							or ("Inserted '%s' (Ctrl+Z to undo)"):format(item.name or "model")
						self:toast(msg .. " — Ctrl+Z to undo", "success")
						insertBtn.Text = "✓ Inserted"
						self:addToolboxRecent(item.id, item.name)
						refreshRecents()
					else
						self:toast(res.error or "Insert failed.", "error")
						insertBtn.Text = "＋ Retry"
					end
				end)
			end)

			-- Favorite toggle — pin a model to the favorites strip for instant re-use.
			local favBtn = button(self:isToolboxFavorite(item.id) and "⭐ Favorited" or "☆ Favorite", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = C.Panel, TextSize = 10, LayoutOrder = 3 })
			favBtn.Parent = card
			favBtn.Activated:Connect(function()
				local nowFav = self:toggleToolboxFavorite(item.id, item.name)
				favBtn.Text = nowFav and "⭐ Favorited" or "☆ Favorite"
				refreshRecents()
			end)

			-- Asset ID row at the bottom (also copy-selectable via the search box).
			Create("TextLabel", {
				Text = "ID: " .. tostring(item.id or "?"), Font = Theme.FontMono, TextSize = 10,
				TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 4, Parent = card,
			})
		end
	end

	local function runSearch(query)
		query = query and query:gsub("^%s+", ""):gsub("%s+$", "") or ""
		-- Blend in the active category so filters narrow the results.
		local full = (currentCategory ~= "") and (currentCategory .. " " .. query) or query
		if full == "" then return end
		status("🔎 Searching the Toolbox…")
		task.spawn(function()
			local res = self.deps.ai:searchToolbox(full)
			if res.ok then
				renderResults(res.results or {})
			else
				status(res.error or "Search failed.", "error")
			end
		end)
	end

	searchBtn.Activated:Connect(function()
		runSearch(searchBox.Text)
	end)
	bulkBtn.Activated:Connect(function()
		if #lastResults == 0 then return end
		bulkBtn.Text = "Inserting…"
		bulkBtn.Active = false
		task.spawn(function()
			local ok, fail = 0, 0
			for _, item in ipairs(lastResults) do
				local res = self.deps.apply:insertAsset(item.id, item.name)
				if res.ok then
					ok += 1
					self:addToolboxRecent(item.id, item.name)
				else
					fail += 1
				end
				task.wait(0.15)
			end
			refreshRecents()
			self:toast(("Inserted %d model(s)%s. Ctrl+Z to undo."):format(ok, fail > 0 and (", " .. fail .. " failed") or ""), ok > 0 and "success" or "error")
			bulkBtn.Active = true
			updateBulk()
		end)
	end)
	searchBox.FocusLost:Connect(function(enter)
		if enter then runSearch(searchBox.Text) end
	end)
	idBtn.Activated:Connect(function()
		local id = tonumber(idBox.Text)
		if not id then
			self:toast("Enter a valid numeric Asset ID.", "warning")
			return
		end
		idBtn.Text = "…"
		task.spawn(function()
			local res = self.deps.apply:insertAsset(id)
			idBtn.Text = "Insert"
			if res.ok then
				local msg = (res.results and res.results[1] and res.results[1].message)
					or ("Inserted asset " .. id)
				self:toast(msg .. " — Ctrl+Z to undo", "success")
				idBox.Text = ""
				self:addToolboxRecent(id, "Asset " .. tostring(id))
				refreshRecents()
			else
				self:toast(res.error or "Insert failed.", "error")
			end
		end)
	end)
end

-- Toolbox recents — persisted list of {id, name} for one-click re-insert.
local TOOLBOX_RECENTS_KEY = "Bloxsmith_ToolboxRecents"

function App:loadToolboxRecents()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(TOOLBOX_RECENTS_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end

function App:addToolboxRecent(id, name)
	id = tonumber(id)
	if not id then
		return
	end
	local list = self:loadToolboxRecents()
	-- De-dupe: drop any existing entry with the same id, then prepend.
	for i = #list, 1, -1 do
		if tonumber(list[i].id) == id then
			table.remove(list, i)
		end
	end
	table.insert(list, 1, { id = id, name = name or ("Asset " .. tostring(id)) })
	while #list > 12 do
		table.remove(list)
	end
	pcall(function()
		self.deps.plugin:SetSetting(TOOLBOX_RECENTS_KEY, list)
	end)
end

-- Toolbox favorites — pinned {id, name} models for one-click re-insert.
local TOOLBOX_FAVORITES_KEY = "Bloxsmith_ToolboxFavorites"

function App:loadToolboxFavorites()
	local ok, data = pcall(function()
		return self.deps.plugin:GetSetting(TOOLBOX_FAVORITES_KEY)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return {}
end

function App:isToolboxFavorite(id)
	id = tonumber(id)
	if not id then
		return false
	end
	for _, item in ipairs(self:loadToolboxFavorites()) do
		if tonumber(item.id) == id then
			return true
		end
	end
	return false
end

function App:saveToolboxFavorites(list)
	pcall(function()
		self.deps.plugin:SetSetting(TOOLBOX_FAVORITES_KEY, list)
	end)
end

function App:removeToolboxFavorite(id)
	id = tonumber(id)
	if not id then
		return
	end
	local list = self:loadToolboxFavorites()
	for i = #list, 1, -1 do
		if tonumber(list[i].id) == id then
			table.remove(list, i)
		end
	end
	self:saveToolboxFavorites(list)
end

-- Toggle a model's favorite state; returns true if it is now a favorite.
function App:toggleToolboxFavorite(id, name)
	id = tonumber(id)
	if not id then
		return false
	end
	local list = self:loadToolboxFavorites()
	for i = #list, 1, -1 do
		if tonumber(list[i].id) == id then
			table.remove(list, i)
			self:saveToolboxFavorites(list)
			return false
		end
	end
	table.insert(list, 1, { id = id, name = name or ("Asset " .. tostring(id)) })
	while #list > 20 do
		table.remove(list)
	end
	self:saveToolboxFavorites(list)
	return true
end




-- A labelled control that cycles through a list of options on click and
-- persists the chosen value to a plugin setting.
function App:cyclePref(parent, label, settingKey, options, default)
	Create("TextLabel", { Text = label, Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Parent = parent })
	local current = self.deps.ai.plugin:GetSetting(settingKey) or default
	local idx = 1
	for i, opt in ipairs(options) do
		if opt == current then idx = i break end
	end
	local btn = button("◀   " .. current .. "   ▶", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.Panel, TextColor3 = C.Text })
	stroke(C.Border).Parent = btn
	btn.Parent = parent
	local function set(newIdx)
		idx = ((newIdx - 1) % #options) + 1
		btn.Text = "◀   " .. options[idx] .. "   ▶"
		self.deps.ai.plugin:SetSetting(settingKey, options[idx])
	end
	btn.Activated:Connect(function()
		set(idx + 1)
		self:toast(label .. ": " .. options[idx], "success")
	end)
end

function App:buildSettingsView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = C.Border, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 8), Parent = view })
	pad(0).Parent = view

	-- Customization
	Create("TextLabel", { Text = "🎨 Customization", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = view })

	self:cyclePref(view, "AI personality", Config.Settings.Persona, Config.Personas, Config.Defaults.Persona)
	self:cyclePref(view, "Response length", Config.Settings.ResponseLength, Config.ResponseLengths, Config.Defaults.ResponseLength)

	Create("TextLabel", { Text = "Custom instructions", Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Parent = view })
	local ci = self.deps.ai.plugin:GetSetting(Config.Settings.CustomInstructions) or ""
	local ciBox = Create("TextBox", { PlaceholderText = "e.g. Always use OOP modules. Comment every function. Prefer Knit framework.", Text = ci, Font = Theme.Font, TextSize = 12, TextColor3 = C.Text, PlaceholderColor3 = C.TextFaint, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, MultiLine = true, TextWrapped = true, Size = UDim2.new(1, 0, 0, 70), Parent = view }, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local ciSave = button("Save custom instructions", { Size = UDim2.new(1, 0, 0, 30) })
	ciSave.Parent = view
	ciSave.Activated:Connect(function()
		local txt = string.sub(ciBox.Text or "", 1, Config.MaxCustomInstructions)
		self.deps.ai.plugin:SetSetting(Config.Settings.CustomInstructions, txt)
		self:toast("Custom instructions saved.", "success")
	end)

	Create("TextLabel", { Text = "Personality, length and custom instructions shape every AI reply and are sent securely with each request.", Font = Theme.Font, TextSize = 11, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	-- Connection
	Create("TextLabel", { Text = "🔌 Connection", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = view })

	Create("TextLabel", { Text = "Backend URL", Font = Theme.FontBold, TextSize = 13, TextColor3 = C.Text, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18), Parent = view })
	local urlBox = Create("TextBox", { Text = self.deps.ai:getUrl(), Font = Theme.FontMono, TextSize = 12, TextColor3 = C.Text, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextWrapped = true, Size = UDim2.new(1, 0, 0, 50), Parent = view }, { corner(UDim.new(0, 6)), pad(6), stroke(C.Border) })
	local save = button("Save backend URL", { Size = UDim2.new(1, 0, 0, 32) })
	save.Parent = view
	save.Activated:Connect(function()
		self.deps.ai:setUrl(urlBox.Text)
		self:toast("Backend URL saved.", "success")
	end)

	Create("TextLabel", { Text = "The plugin never stores an AI key — it calls a secure backend that holds the provider credentials. All requests are validated, rate-limited and sent over HTTPS.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	-- Danger Zone: full place reset.
	Create("TextLabel", { Text = "⚠️ Danger Zone", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Error, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = view })
	Create("TextLabel", { Text = "Refresh place — permanently removes ALL scripts, models, GUIs and assets across Workspace, ServerScriptService, ReplicatedStorage, StarterGui, StarterPlayer, Lighting and more. The Baseplate is kept. Undo the whole wipe with Ctrl+Z.", Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = view })

	local resetBtn = button("🔄 Refresh place (keep Baseplate)", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.Error, TextColor3 = C.Bg })
	resetBtn.Parent = view
	local armed = false
	local resetToken = 0
	resetBtn.Activated:Connect(function()
		if not armed then
			armed = true
			resetBtn.Text = "⚠️ Click again to confirm wipe"
			resetToken += 1
			local myToken = resetToken
			task.delay(4, function()
				if armed and myToken == resetToken then
					armed = false
					resetBtn.Text = "🔄 Refresh place (keep Baseplate)"
				end
			end)
			return
		end
		armed = false
		resetToken += 1
		resetBtn.Text = "🔄 Refresh place (keep Baseplate)"
		local res = self.deps.apply:resetPlace(true)
		if res.ok then
			self:toast(("Place refreshed — removed %d item(s). Ctrl+Z to undo."):format(res.removed or 0), "success")
		else
			self:toast("Refresh failed: " .. (res.error or "unknown"), "error")
		end
	end)

	Create("TextLabel", { Text = ("Bloxsmith v%s"):format(Config.Version), Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), Parent = view })
end

--========================================================================
-- Changelog (what's new in each version)
--========================================================================
function App:buildChangelogView(parent)
	local view = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = C.Border, BorderSizePixel = 0, Parent = parent })
	Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = view })
	pad(0).Parent = view

	Create("TextLabel", { Text = ("📝 What's New — Bloxsmith v%s"):format(Config.Version), Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0, Parent = view })

	for i, entry in ipairs(Config.Changelog or {}) do
		local isLatest = (i == 1)
		local card = Create("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = view }, { corner(UDim.new(0, 8)), pad(10), stroke(isLatest and C.Accent or C.Border) })
		Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

		local header = ("v%s — %s"):format(entry.version, entry.title or "")
		if isLatest then header = "⭐ " .. header .. "  (latest)" end
		Create("TextLabel", { Text = header, Font = Theme.FontBold, TextSize = 14, TextColor3 = isLatest and C.Accent or C.Text, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 0, Parent = card })
		Create("TextLabel", { Text = entry.date or "", Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1, Parent = card })

		for j, change in ipairs(entry.changes or {}) do
			Create("TextLabel", { Text = "• " .. change, Font = Theme.Font, TextSize = 12, TextColor3 = C.TextDim, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1 + j, Parent = card })
		end
	end
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
	self.gui = gui
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

	Create("TextLabel", { Text = "🔨 Bloxsmith", Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Accent, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 24), Parent = sidebar })
	Create("TextLabel", { Text = ("v%s"):format(Config.Version), Font = Theme.Font, TextSize = 11, TextColor3 = C.TextFaint, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Parent = sidebar })

	-- Content area
	local content = Create("Frame", { BackgroundColor3 = C.Bg, Size = UDim2.new(1, -118, 1, 0), Position = UDim2.new(0, 118, 0, 0), BorderSizePixel = 0, Parent = gui }, { pad(10) })

	local nav = { "Chat", "Tools", "Toolbox", "Analysis", "Health", "Errors", "Changelog", "Settings" }
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
	self:buildToolboxView(self.views.Toolbox)
	self:buildAnalysisView(self.views.Analysis)
	self:buildHealthView(self.views.Health)
	self:buildErrorsView(self.views.Errors)
	self:buildChangelogView(self.views.Changelog)
	self:buildSettingsView(self.views.Settings)

	self:selectView("Chat")
	-- Restore the previous conversation (memory). Only greet on a fresh start.
	local restored = self:restoreActiveSession()
	if restored then
		self:toast("Restored your last conversation.", "success")
	else
		self:addBubble("assistant", "👋 **Welcome to Bloxsmith!** I can generate scripts, UIs and full game systems, build anything in Studio, fix & optimize code, and insert free models from the **Toolbox** tab. I remember our conversation across sessions. You'll see my 💭 thinking as I work, and you approve every change. Ask me anything!")
	end
end

return App
