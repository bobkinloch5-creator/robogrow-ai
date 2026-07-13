
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
	for header, body in string.gmatch(text, "```([^\n]*)\n([%s%S]-)```") do
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
	local thinking = string.match(text, "```bloxsmith:thinking%s*\n([%s%S]-)```")
	if thinking then
		local cleaned = string.gsub(text, "```bloxsmith:thinking%s*\n[%s%S]-```", "", 1)
		return (thinking:gsub("^%s+", ""):gsub("%s+$", "")), cleaned
	end
	return nil, text
end

-- Repairs JS-style single-quoted JSON without corrupting content. A blind
-- '->" replace breaks the moment generated code contains an apostrophe
-- (e.g. "it's", "player's Tool") — this walks the string tracking quote
-- state so only quotes acting as string *delimiters* get converted; a `'`
-- that reads as a literal apostrophe (not followed by a JSON structural
-- character) is left alone, and any real `"` found inside a converted
-- string gets escaped so it doesn't terminate early.
local function smartSingleQuoteRepair(json)
	local out, i, n = {}, 1, #json
	local inDouble, inSingle = false, false
	while i <= n do
		local c = json:sub(i, i)
		if c == "\\" and i < n then
			out[#out + 1] = c
			out[#out + 1] = json:sub(i + 1, i + 1)
			i = i + 2
		elseif inDouble then
			if c == '"' then inDouble = false end
			out[#out + 1] = c
			i = i + 1
		elseif inSingle then
			if c == "'" then
				local j = i + 1
				while j <= n and json:sub(j, j):match("%s") do j = j + 1 end
				local nextCh = json:sub(j, j)
				if nextCh == "" or nextCh == "," or nextCh == "}" or nextCh == "]" or nextCh == ":" then
					out[#out + 1] = '"'
					inSingle = false
				else
					out[#out + 1] = "'" -- literal apostrophe; unescaped ' is valid inside a JSON string
				end
			elseif c == '"' then
				out[#out + 1] = '\\"'
			else
				out[#out + 1] = c
			end
			i = i + 1
		else
			if c == '"' then
				inDouble = true
				out[#out + 1] = c
			elseif c == "'" then
				inSingle = true
				out[#out + 1] = '"'
			else
				out[#out + 1] = c
			end
			i = i + 1
		end
	end
	return table.concat(out)
end

-- Extract JSON actions from a ```bloxsmith:actions ... ``` block as a safety net
-- in case the backend returns a reply but fails to populate decoded.actions.
-- Returns (actionsTable or nil, textWithActionsRemoved, foundBlock).
function Parser.extractActions(text)
	if type(text) ~= "string" then
		return nil, text, false
	end
	local json = string.match(text, "```bloxsmith:actions%s*\n([%s%S]-)```")
	if not json or json == "" then
		return nil, text, false
	end
	local cleaned = string.gsub(text, "```bloxsmith:actions%s*\n[%s%S]-```", "", 1)

	local HttpService = game:GetService("HttpService")

	-- 1) Try as-is first — the common case, and zero risk of corrupting code.
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if ok and type(decoded) == "table" then
		return decoded, cleaned, true
	end

	-- 2) Strip trailing commas, a common small LLM slip.
	local noTrailingCommas = (json:gsub(",(%s*[%]}])", "%1"))
	local ok2, decoded2 = pcall(function()
		return HttpService:JSONDecode(noTrailingCommas)
	end)
	if ok2 and type(decoded2) == "table" then
		return decoded2, cleaned, true
	end

	-- 3) Quote-aware repair for JS-style single-quoted objects (see above) —
	--    only used as a last resort, and safe for apostrophes in code.
	local repaired = smartSingleQuoteRepair(noTrailingCommas)
	local ok3, decoded3 = pcall(function()
		return HttpService:JSONDecode(repaired)
	end)
	if ok3 and type(decoded3) == "table" then
		return decoded3, cleaned, true
	end

	warn("[Bloxsmith Action Parser Error]: Failed to parse actions JSON block.")
	warn("Error (raw):", tostring(decoded))
	warn("Error (repaired):", tostring(decoded3))
	print("[Bloxsmith Malformed Actions JSON]:\n" .. tostring(json))

	return nil, cleaned, true
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

-- Escape the characters that are special inside a Roblox RichText string.
local function escapeRich(s)
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end

--[[
	toRichText(text, opts) -> string
	Converts a subset of Markdown into Roblox RichText so AI replies render as
	clean formatted text instead of raw **asterisks**, #hashes and `backticks`.

	Supported:
	  # / ## / ###  headers        -> bold (larger via <font size>)
	  **bold**  / __bold__          -> <b>…</b>
	  *italic*  / _italic_          -> <i>…</i>
	  `inline code`                 -> colored monospace-style span
	  - / * / • bullets             -> • bullet
	  1. numbered lists             -> kept as "1." with a thin space
	  ---/*** horizontal rules      -> a subtle divider line
	opts.codeColor = "#RRGGBB" for inline code (defaults to a soft cyan).
]]
function Parser.toRichText(text, opts)
	if type(text) ~= "string" then
		return ""
	end
	opts = opts or {}
	local codeColor = opts.codeColor or "#8be9fd"

	-- Escape first so user/AI angle brackets never inject tags.
	local out = escapeRich(text)

	-- Process line-by-line for block-level markdown (headers, bullets, rules).
	local lines = string.split(out, "\n")
	for i, line in ipairs(lines) do
		local trimmed = line:gsub("^%s+", "")

		-- Horizontal rule.
		if trimmed:match("^%-%-%-+$") or trimmed:match("^%*%*%*+$") or trimmed:match("^___+$") then
			lines[i] = '<font color="#3a4356">──────────</font>'
		else
			-- Headers (#, ##, ###) -> bold, slightly larger for the biggest.
			local hashes, htext = line:match("^%s*(#+)%s+(.*)$")
			if hashes then
				local size = #hashes == 1 and 17 or (#hashes == 2 and 15 or 14)
				lines[i] = ('<font size="%d"><b>%s</b></font>'):format(size, htext)
			else
				-- Bullets: "- ", "* ", "+ " -> "• "
				local indent, btext = line:match("^(%s*)[%-%*%+]%s+(.*)$")
				if btext then
					lines[i] = indent .. "• " .. btext
				end
			end
		end
	end
	out = table.concat(lines, "\n")

	-- Inline code first so ** or * inside code isn't reinterpreted.
	out = out:gsub("`([^`]+)`", '<font color="' .. codeColor .. '">%1</font>')

	-- Bold (** or __) before italic so the ** pair wins over single *.
	out = out:gsub("%*%*(.-)%*%*", "<b>%1</b>")
	out = out:gsub("__(.-)__", "<b>%1</b>")

	-- Italic (single * or _). Require non-space next to the marker so it does
	-- not eat stray asterisks.
	out = out:gsub("%*(%S.-%S)%*", "<i>%1</i>")
	out = out:gsub("%*(%S)%*", "<i>%1</i>")

	return out
end

return Parser
