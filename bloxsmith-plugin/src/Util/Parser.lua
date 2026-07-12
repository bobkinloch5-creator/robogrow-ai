--[[
	Parser.lua
	Turns AI markdown replies into actionable pieces:
	- extractBlocks: fenced code blocks with optional `path= name= class=` hints,
	  converted into apply-ready action tables.
]]
local Parser = {}

-- Parse a fence header like: lua path=ServerScriptService/Shop name=Shop class=Script
local function parseHeader(header)
	local meta = { lang = "lua" }
	local firstWord = string.match(header, "^%s*([%w_+-]+)")
	if firstWord then
		meta.lang = firstWord
	end
	for key, value in string.gmatch(header, "(%w+)=([^%s]+)") do
		meta[key] = value
	end
	return meta
end

-- Returns an array of { source, lang, path, name, class }.
function Parser.extractBlocks(text)
	local blocks = {}
	if type(text) ~= "string" then
		return blocks
	end
	-- Match ```<header>\n<body>```
	for header, body in string.gmatch(text, "```([^\n]*)\n(.-)```") do
		local meta = parseHeader(header)
		if meta.lang == "bloxsmith:actions" or meta.lang == "bloxsmith:thinking" then
			-- handled separately (agent actions / thinking panel); skip here.
		else
			table.insert(blocks, {
				source = body,
				lang = meta.lang,
				path = meta.path,
				name = meta.name,
				class = meta.class,
			})
		end
	end
	return blocks
end

-- Extract the leading ```bloxsmith:thinking ... ``` block (the AI's plan).
-- Returns (thinkingText or nil, textWithThinkingRemoved).
function Parser.extractThinking(text)
	if type(text) ~= "string" then
		return nil, text
	end
	local thinking = string.match(text, "```bloxsmith:thinking%s*\n(.-)```")
	if thinking then
		local cleaned = string.gsub(text, "```bloxsmith:thinking%s*\n.-```", "", 1)
		return (thinking:gsub("^%s+", ""):gsub("%s+$", "")), cleaned
	end
	return nil, text
end

-- Convert a code block into a create_script action (best-effort defaults).
function Parser.blockToAction(block, index)
	local class = block.class
	if class ~= "Script" and class ~= "LocalScript" and class ~= "ModuleScript" then
		-- Infer from content.
		if string.find(block.source, "game.Players.LocalPlayer") or string.find(block.source, "PlayerGui") then
			class = "LocalScript"
		elseif string.find(block.source, "return%s") and not string.find(block.source, "OnServerEvent") then
			class = "ModuleScript"
		else
			class = "Script"
		end
	end
	local path = block.path
	local name = block.name
	if path and not name then
		-- If the path includes the script name as last segment, split it out.
		local segs = string.split(path, "/")
		if #segs > 1 then
			name = segs[#segs]
			table.remove(segs, #segs)
			path = table.concat(segs, "/")
		end
	end
	return {
		action = "create_script",
		path = path or (class == "LocalScript" and "StarterPlayer/StarterPlayerScripts" or "ServerScriptService"),
		name = name or ("BloxsmithScript" .. tostring(index or 1)),
		class = class,
		source = block.source,
	}
end

return Parser
