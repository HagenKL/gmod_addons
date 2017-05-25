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
		DefaultColor = Color(255,128,0,255),
		DefaultPct = "0.15", -- Role Percentage
		DefaultMax = "1", -- Default Limit
		DefaultMin = "7", -- Default Min Players for Role to be there
		DefaultCredits = "0", -- Default Credits
		IsEvilReplacement = true, -- Is Replacement for one traitor
		ShopFallBack = true, -- Falls back to normal shop items, eg. all traitor items
		indicator_mat = Material("vgui/ttt/sprite_hunter"), -- Icon above head
		winning_team = WIN_TRAITOR, -- the team it wins with, available are "traitors" and "innocent"
		drawtargetidcircle = true, -- should draw circle
		AllowTeamChat = true, -- team chat
		RepeatingCredits = false,
		DefaultEquip = EQUIP_RADAR
	}
	AddNewRole("HUNTER", Hunter)
end

local function AddJackal()
	local Jackal = { -- table to create new role
		Rolename = "Jackal", -- Normal Name
		String = "jackal", -- String Name
		IsGood = true, -- Fights for the good, special for survivor because he normally wouldnt be good, but we need to do this to prevent breaking addons.
		IsEvil = false, -- Fights for the bad
		IsSpecial = true, -- Is it special, eg. not innocent
		Creditsforkills = true, -- Gets Credits for kills
		ShortString = "jackal", -- for icons
		Short = "jk", -- short for icons, ttt based
		IsDefault = false, -- Is default in TTT, obviously no
		DefaultColor = Color(0, 255, 255),
		DefaultPct = "0.05", -- Role Percentage
		DefaultMax = "1", -- Default Limit
		DefaultMin = "6", -- Default Min Players for Role to be there
		DefaultCredits = "3", -- Default Credits
		IsGoodReplacement = false, -- Is Replacement for one traitor/detective
		ShopFallBack = true, -- Falls back to normal shop items, eg. all traitor items
		--indicator_mat = Material("vgui/ttt/sprite_jackal"), -- Icon above head
		newteam = true, -- the team it wins with, available are "traitors" and "innocent"
		drawtargetidcircle = false, -- should draw circle
		AllowTeamChat = false, -- team chat
		Description = [[You are the Jackal! Terrorist HQ has given you special resources to kill everybody.
		Use them to be the last survivor, but be careful:
		You are on your own and alone!

		Press {menukey} to receive your equipment!]],
		wintext = "The Jackal has won!",
		RepeatingCredits = false,
		Chanceperround = 0.5,
		DefaultEquip = EQUIP_ARMOR
	}
	AddNewRole("JACKAL", Jackal)
end

local function AddRoles()
	AddHunter()
	AddJackal()
	print("TTT Vote Roles have been initialized!")
end

hook.Add("PostGamemodeLoaded", "AddRoles", AddRoles)
