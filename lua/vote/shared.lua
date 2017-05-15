local function AddRoles()
	local Hunter = {
		Rolename = "Totemhunter", -- Normal Name
		String = "hunter", -- String Name
		IsGood = false, -- Fights for the good
		IsSpecial = true, -- Is it special, eg. not innocent
		Creditsforkills = false, -- Gets Credits for kills
		ShortString = "hunter", -- for icons
		Short = "h", -- short for icons, ttt based
		IsDefault = false, -- Is default in TTT, obviously no
		EquipColor = Color(180, 140, 40, 255), -- Equip Menu Color
		HUDColor = Color(200, 140, 25, 200), -- HUD Color
		HUDPickupColor = Color(180, 140, 40, 255), -- Pickup Color
		LangColor = Color(150, 150, 0, 200), -- LANG Color
		WepSwitchColorActive = Color(180, 140, 40, 255), -- Wepswitchactive
		WepSwitchColorDark = Color(160, 140, 60, 155), -- Wepswitchdark
		RowColor = Color(255, 255, 0, 30), -- Scoreboard Color
		DefaultPct = "0.15", -- Role Percentage
		DefaultMax = "1", -- Default Limit
		DefaultMin = "7", -- Default Min Players for Role to be there
		IsReplacement = true, -- Is Replacement for one traitor
		ShopFallBack = true, -- Falls back to normal shop items, eg. all traitor items
		RadarColor = Color(255, 200, 0), -- Radar Color
		indicator_mat = Material("vgui/ttt/sprite_hunter"), -- Icon above head
		winning_team = WIN_TRAITOR, -- the team it wins with, available are "traitors" and "innocent"
		drawtargetidcircle = true, -- should draw circle
		targetidcirclecolor = Color(255, 230, 0, 200), -- circle color
		targetidcolor = Color(255, 230, 0), -- target id color
		AllowTeamChat = true -- team chat
	}
	AddNewRole("HUNTER", Hunter)
	print("TTT Vote Roles have been initialized!")
end

hook.Add("PostGamemodeLoaded", "AddRoles", AddRoles)
