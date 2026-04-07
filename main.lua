local addonName = ...
local printPrefix = "|cffa335ee" .. addonName .. ": |r"

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
	if quickguildinvite_autoinvite == nil then
		quickguildinvite_autoinvite = true
	end
	self:UnregisterEvent("ADDON_LOADED")
	print(printPrefix .. " loaded, use /qginv on or /qginv off to enable or disable the addon")
end

-- Custom draggable invite popup
local inviteQueue = {}
local invitePopup = CreateFrame("Frame", "QuickGuildInvitePopup", UIParent, "BackdropTemplate")
invitePopup:SetSize(280, 100)
invitePopup:SetPoint("CENTER")
invitePopup:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
invitePopup:SetMovable(true)
invitePopup:EnableMouse(true)
invitePopup:RegisterForDrag("LeftButton")
invitePopup:SetScript("OnDragStart", invitePopup.StartMoving)
invitePopup:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	quickguildinvite_popuppos = { point, relPoint, x, y }
end)
invitePopup:SetFrameStrata("DIALOG")
invitePopup:SetClampedToScreen(true)
invitePopup:Hide()

local popupText = invitePopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
popupText:SetPoint("TOP", 0, -20)
popupText:SetWidth(250)

local inviteBtn = CreateFrame("Button", nil, invitePopup, "UIPanelButtonTemplate")
inviteBtn:SetSize(100, 22)
inviteBtn:SetPoint("BOTTOMLEFT", 30, 15)
inviteBtn:SetText("Invite")

local cancelBtn = CreateFrame("Button", nil, invitePopup, "UIPanelButtonTemplate")
cancelBtn:SetSize(100, 22)
cancelBtn:SetPoint("BOTTOMRIGHT", -30, 15)
cancelBtn:SetText("Cancel")

local function restorePopupPosition()
	if quickguildinvite_popuppos then
		local point, relPoint, x, y = unpack(quickguildinvite_popuppos)
		invitePopup:ClearAllPoints()
		invitePopup:SetPoint(point, UIParent, relPoint, x, y)
	end
end

local function showNextInvite()
	if #inviteQueue == 0 then
		invitePopup:Hide()
		return
	end
	local name = table.remove(inviteQueue, 1)
	invitePopup.currentName = name
	local queueCount = #inviteQueue
	if queueCount > 0 then
		popupText:SetText("Invite " .. name .. " to your guild?\n(+" .. queueCount .. " queued)")
	else
		popupText:SetText("Invite " .. name .. " to your guild?")
	end
	restorePopupPosition()
	invitePopup:Show()
end

inviteBtn:SetScript("OnClick", function()
	local name = invitePopup.currentName
	if name then
		GuildInvite(name)
		print(printPrefix .. "Invited " .. name .. " to the guild.")
		print(printPrefix .. "Use /qginv auto to toggle auto-invite on whisper (currently " .. (quickguildinvite_autoinvite and "on" or "off") .. ")")
	end
	showNextInvite()
end)

cancelBtn:SetScript("OnClick", function()
	showNextInvite()
end)

-- Auto-invite: listen for whispers containing "ginv" or "ginvite"
myframe:RegisterEvent("CHAT_MSG_WHISPER")
function myframe:CHAT_MSG_WHISPER(message, sender)
	if not quickguildinvite_autoinvite then return end
	if not IsInGuild() then return end
	if not CanGuildInvite() then return end

	local msg = message:lower()
	if msg:find("ginvite") or msg:find("ginv") then
		-- Ignore if this player is already the current popup or in the queue
		if invitePopup.currentName == sender then return end
		for _, queued in ipairs(inviteQueue) do
			if queued == sender then return end
		end
		table.insert(inviteQueue, sender)
		-- Show immediately if no popup is currently open
		if not invitePopup:IsShown() then
			showNextInvite()
		end
	end
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
	elseif msg == "auto" then
		quickguildinvite_autoinvite = not quickguildinvite_autoinvite
		if quickguildinvite_autoinvite then
			print(printPrefix .. "Auto-invite enabled. Messages containing 'ginv' or 'ginvite' will be invited.")
		else
			print(printPrefix .. "Auto-invite disabled.")
		end
	else
		print(printPrefix .. "Possible commands:")
		print(printPrefix .. "/qginv on - turns on 'Guild invite' in context menu's")
		print(printPrefix .. "/qginv off - turns off 'Guild invite' in context menu's")
		print(printPrefix .. "/qginv auto - toggle auto-invite on whisper (currently " .. (quickguildinvite_autoinvite and "on" or "off") .. ")")
	end
end
