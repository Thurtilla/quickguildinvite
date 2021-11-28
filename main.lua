-- Used to set the player to invite 
local inviteName = ""

local myframe = CreateFrame("Frame")
myframe:RegisterEvent("UNIT_TARGET")

myframe:SetScript(
	"OnEvent",
	function(_, event, ...)
		myframe[event](myframe, ...)
	end
)


function inviteToGuild()
	GuildInvite(inviteName)
end

function addGuildInviteButtonToChat()
	if CanGuildInvite() then
		for i = 1, #UnitPopupMenus["FRIEND"] do
			if UnitPopupMenus["FRIEND"][i] == "GuildInvite" then return end
			if UnitPopupMenus["FRIEND"][i] == "WHISPER" then
				tinsert(UnitPopupMenus["FRIEND"], i - 1, "GuildInvite")
				return
			end
		end
	end
end

addGuildInviteButtonToChat()

function myframe:UNIT_TARGET(unitid)
	if not CanGuildInvite() then return end
	inviteIndex = #UnitPopupMenus["PLAYER"] - 1
	if unitid == "player" and UnitExists("target") then
		if UnitFactionGroup("target") == UnitFactionGroup("player") and UnitIsPlayer("target") then
			for i = 1, #UnitPopupMenus["PLAYER"] do
				if UnitPopupMenus["PLAYER"][i] == "WHISPER" then
					inviteIndex = i
				end
				if UnitPopupMenus["PLAYER"][i] == "GuildInvite" then return end
				end
			end
			print("adding ginv xD")
			tinsert(UnitPopupMenus["PLAYER"], inviteIndex - 1, "GuildInvite")
		end
	end

UnitPopupButtons["GuildInvite"] = {
	text = "Guild invite",
	tooltipText = "Invites the player to join your guild",
	dist = 0,
	func = function()
		inviteToGuild()
	end
}

function Assignfunchook(dropdownMenu, which, unit, name, userData, ...)
	inviteName = _G["DropDownList" .. "1" .. "Button" .. "1"].value
	for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
		local button = _G["DropDownList" .. UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i]
		if button.value == "GuildInvite" then
			button.func = UnitPopupButtons["GuildInvite"].func
		end
	end
end

hooksecurefunc("UnitPopup_ShowMenu", Assignfunchook)
