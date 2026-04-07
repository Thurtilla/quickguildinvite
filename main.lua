local addonName = ...
local printPrefix = "|cffa335ee" .. addonName .. "|r: "

local myframe = CreateFrame("Frame")
myframe:RegisterEvent("ADDON_LOADED")
myframe:SetScript("OnEvent", function(_, event, ...)
	myframe[event](myframe, ...)
end)

function myframe:ADDON_LOADED(name)
	if name ~= addonName then return end
	if quickguildinvite_enabled == nil then
		print(printPrefix .. "First load, enabling addon")
		quickguildinvite_enabled = true
	end
	self:UnregisterEvent("ADDON_LOADED")
	print(printPrefix .. "Addon loaded, use /qginv on or /qginv off to enable or disable the addon")
end

-- Find the position after "Interact" title by checking element text.
-- Elements created via MenuUtil have .text on the proxy; Blizzard's own
-- elements may not, so we fall back to a per-tag default position.
local FALLBACK_INTERACT_POS = {
	MENU_UNIT_PLAYER = 6,
	MENU_UNIT_FRIEND = 6,
}

local function findInsertPosition(rootDescription)
	local index = 0
	for _, elem in rootDescription:EnumerateElementDescriptions() do
		index = index + 1
		local text = elem.text
		if text and (text == "Interact" or text == INTERACT) then
			return index + 1
		end
	end
	-- Fall back to a known position per menu tag
	local tag = rootDescription.tag
	return tag and FALLBACK_INTERACT_POS[tag] or nil
end

-- New retail-style menu modification for unit context menus
local function addGuildInviteButton(owner, rootDescription, contextData)
	if not quickguildinvite_enabled then return end

	-- We must be in a guild and have invite permission
	if not IsInGuild() then return end
	if not CanGuildInvite() then return end

	local name
	if contextData then
		name = contextData.name
		if not name and contextData.unit then
			name = GetUnitName(contextData.unit, true)
		end
	end
	if not name then return end

	-- If right-clicking a guild/officer chat message, they're already in our guild
	local chatType = contextData.chatType
	if chatType == "GUILD" or chatType == "OFFICER" then return end

	-- If we have a unit, check if they're already in a guild
	if contextData.unit then
		local guildName = GetGuildInfo(contextData.unit)
		if guildName then return end
	end

	local guildInviteFunc = function()
		GuildInvite(name)
	end

	-- MenuUtil.CreateButton creates a standalone description (no auto-append),
	-- so Insert only adds it once — no duplicate.
	local button = MenuUtil.CreateButton("Guild Invite", guildInviteFunc)
	local pos = findInsertPosition(rootDescription)
	if pos then
		rootDescription:Insert(button, pos)
	else
		rootDescription:Insert(button)
	end
end

Menu.ModifyMenu("MENU_UNIT_PLAYER", addGuildInviteButton)
Menu.ModifyMenu("MENU_UNIT_FRIEND", addGuildInviteButton)

SLASH_QUICKGUILDINVITE1, SLASH_QUICKGUILDINVITE2 = "/quickguildinvite", "/qginv"
SlashCmdList["QUICKGUILDINVITE"] = function(msg)
	if msg == "on" then
		print(printPrefix .. "Addon will now show 'Guild invite' in context menu's. Use /qginv off to hide.")
		quickguildinvite_enabled = true
	elseif msg == "off" then
		print(printPrefix .. "Addon is now disabled, to turn on, use /qginv on")
		quickguildinvite_enabled = false
	else
		print(printPrefix .. "Possible commands:")
		print(printPrefix .. "/qginv on - turns on 'Guild invite' in context menu's")
		print(printPrefix .. "/qginv off - turns off 'Guild invite' in context menu's")
	end
end
