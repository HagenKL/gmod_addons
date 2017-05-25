local function AddHunter()
	local Hunter = {  -- table to create new role
		Rolename = "Totemhunter", -- Normal Name
		String = "hunter", -- String Name
		IsGood = false, -- Fights for the good
		IsEvil = true, -- Fights for the bad
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
		DefaultCredits = "0", -- Default Credits
		IsEvilReplacement = true, -- Is Replacement for one traitor
		ShopFallBack = true, -- Falls back to normal shop items, eg. all traitor items
		RadarColor = Color(255, 200, 0), -- Radar Color
		indicator_mat = Material("vgui/ttt/sprite_hunter"), -- Icon above head
		winning_team = WIN_TRAITOR, -- the team it wins with, available are "traitors" and "innocent"
		drawtargetidcircle = true, -- should draw circle
		targetidcirclecolor = Color(255, 230, 0, 200), -- circle color
		targetidcolor = Color(255, 230, 0), -- target id color
		AllowTeamChat = true, -- team chat
		RepeatingCredits = false,
		DefaultEquip = EQUIP_RADAR
	}
	AddNewRole("HUNTER", Hunter)
end

local function AddSurvivor()
	local Survivor = { -- table to create new role
		Rolename = "Survivor", -- Normal Name
		String = "survivor", -- String Name
		IsGood = true, -- Fights for the good, special for survivor because he normally wouldnt be good, but we need to do this to prevent breaking addons.
		IsEvil = false, -- Fights for the bad
		IsSpecial = true, -- Is it special, eg. not innocent
		Creditsforkills = true, -- Gets Credits for kills
		ShortString = "survivor", -- for icons
		Short = "sv", -- short for icons, ttt based
		IsDefault = false, -- Is default in TTT, obviously no
		EquipColor = Color(150, 150, 150, 255), -- Equip Menu Color
		HUDColor = Color(120, 150, 135, 200), -- HUD Color
		HUDPickupColor = Color(150, 150, 150, 255), -- Pickup Color
		LangColor = Color(150, 150, 150, 200), -- LANG Color
		WepSwitchColorActive = Color(50, 50, 50, 255), -- Wepswitchactive
		WepSwitchColorDark = Color(130, 150, 170, 155), -- Wepswitchdark
		RowColor = Color(150, 150, 150), -- Scoreboard Color
		DefaultPct = "0.05", -- Role Percentage
		DefaultMax = "1", -- Default Limit
		DefaultMin = "6", -- Default Min Players for Role to be there
		DefaultCredits = "4", -- Default Credits
		IsGoodReplacement = false, -- Is Replacement for one traitor/detective
		ShopFallBack = true, -- Falls back to normal shop items, eg. all traitor items
		--RadarColor = Color(150, 150, 0), -- Radar Color -- cant be seen anyway
		--indicator_mat = Material("vgui/ttt/sprite_survivor"), -- Icon above head
		newteam = true, -- the team it wins with, available are "traitors" and "innocent"
		drawtargetidcircle = false, -- should draw circle
		--targetidcirclecolor = Color(255, 230, 0, 200), -- circle color
		--targetidcolor = Color(255, 230, 0), -- target id color
		AllowTeamChat = false, -- team chat
		wincolor = Color(150, 150, 150), -- Color on the win board
		Description = [[You are a Survivor! Terrorist HQ has given you special resources to kill everybody.
		Use them to be the last survivor, but be careful:
		You are on your own and alone!

		Press {menukey} to receive your equipment!]],
		wintext = "The Survivor has won!",
		RepeatingCredits = false,
		Chanceperround = 0.334,
		DefaultEquip = EQUIP_ARMOR
	}
	AddNewRole("SURVIVOR", Survivor)
end

local function AddRoles()
	AddHunter()
	AddSurvivor()
	print("TTT Vote Roles have been initialized!")
end

hook.Add("PostGamemodeLoaded", "AddRoles", AddRoles)
