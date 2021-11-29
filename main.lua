local addonName = "quickguildinvite"
local ADDON = "QuickGuildInvite: "
local gInvIndex

local myframe = CreateFrame("Frame")
myframe:RegisterEvent("ADDON_LOADED")

myframe:SetScript(
	"OnEvent",
	function(_, event, ...)
		myframe[event](myframe, ...)
	end
)

SLASH_QUICKGUILDINVITE1, SLASH_QUICKGUILDINVITE2 = "/quickguildinvite", "/qginv"
SlashCmdList["QUICKGUILDINVITE"] = function(msg)
	if msg == "on" then
		print(ADDON .. "Addon will now show 'Guild invite' in context menu's. Use /qginv off to hide.")
		quickguildinvite_enabled = true
		toggleOnContext()
	elseif msg == "off" then
		print(ADDON .. "Addon is now disabled, to turn on, use /qginv on")
		quickguildinvite_enabled = false
		toggleOnContext()
	else
		print(ADDON .. "Possible commands is:")
		print(ADDON .. "/qginv on - turns on 'Guild invite' in context menu's")
		print(ADDON .. "/sinv off - turns off 'Guild invite' in context menu's")
	end
end

function myframe:ADDON_LOADED(name)
	if name ~= addonName then
		return
	end
	if quickguildinvite_enabled == nil then
		print(ADDON .. "First load, enabling addon")
		quickguildinvite_enabled = true
	end
	if quickguildinvite_enabled == true then
		toggleOnContext()
	end
end

function toggleOnContext()
	if quickguildinvite_enabled then
		for k, v in pairs({"PLAYER", "FRIEND"}) do
			local popupMenu = UnitPopupMenus[v]
			for i = 1, #popupMenu do
				if popupMenu[i] == "GuildInvite" then
					break
				end
				if popupMenu[i] == "INTERACT_SUBSECTION_TITLE" and popupMenu[i + 1] ~= "GuildInvite" then
					gInvIndex = i + 1
					tinsert(popupMenu, gInvIndex, "GuildInvite")
					break
				end
			end
		end
	else
		for k, v in pairs({"PLAYER", "FRIEND"}) do
			local popupMenu = UnitPopupMenus[v]
			if popupMenu[gInvIndex] == "GuildInvite" then
				tremove(popupMenu, gInvIndex)
			end
		end
	end
end

function inviteToGuild(name)
	GuildInvite(name)
end

UnitPopupButtons["GuildInvite"] = {
	text = "Guild invite",
	tooltipText = "Invites the player to join your guild",
	dist = 0,
	func = function()
		print(ADDON .. "No player found, please try again.")
	end
}

function Assignfunchook(dropdownMenu, which, unit, name, userData, ...)
	for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
		local button = _G["DropDownList" .. UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i]
		if button.value == "GuildInvite" then
			button.func = function()
				inviteToGuild(dropdownMenu.name)
			end
			break
		end
	end
end

hooksecurefunc("UnitPopup_ShowMenu", Assignfunchook)
