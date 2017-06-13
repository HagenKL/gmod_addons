SWEP.Base = "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.HoldType = "slam"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = WEAPON_EQUIP2

if SERVER then
	resource.AddWorkshop("662342819")
	AddCSLuaFile( "shared.lua" )
	resource.AddFile("materials/VGUI/ttt/icon_randomat.vmt")
	util.AddNetworkString( "RandomatMessage" )
	util.AddNetworkString("RandomatOverrideTargetID")
	util.AddNetworkString("RandomatHooks1")
	util.AddNetworkString("RandomatHooks2")
	util.AddNetworkString("RandomatFixClientSideWeapons")
	function RandomatBroadcast(...)
		local msg = {...}
		net.Start("RandomatMessage")
		net.WriteTable(msg)
		net.Broadcast()
	end
end

if CLIENT then

	SWEP.PrintName = "Randomat-3000"
	SWEP.Slot = 7

	SWEP.ViewModelFOV = 60
	SWEP.ViewModelFlip = false

	SWEP.Icon = "VGUI/ttt/icon_randomat"
	SWEP.EquipMenuData = {
		type = "weapon",
		desc = "The Randomat-3000 will do something Random! \nWho guessed that!"
	};
	net.Receive("RandomatMessage",function(len)
			local msg = net.ReadTable()
			chat.AddText(unpack(msg))
			chat.PlaySound()
			surface.PlaySound("weapons/c4_initiate.wav")
		end)
	function SWEP:PrimaryAttack()
	end
end

SWEP.Primary.Delay = 10
SWEP.Primary.Recoil = 0
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 1
SWEP.Primary.Damage = 0
SWEP.Primary.Cone = 0
SWEP.Primary.Ammo = nil
SWEP.Primary.ClipSize = -1
SWEP.Primary.ClipMax = -1
SWEP.Primary.DefaultClip = -1
SWEP.AmmoEnt = nil

SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.UseHands = true
SWEP.HeadshotMultiplier = 0
SWEP.CanBuy = { ROLE_DETECTIVE }
SWEP.LimitedStock = true
SWEP.Primary.Sound = ""

SWEP.ViewModel = "models/weapons/gamefreak/c_csgo_c4.mdl"
SWEP.WorldModel = "models/weapons/gamefreak/w_c4_planted.mdl"
SWEP.Weight = 2

function SWEP:OnRemove()
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
		RunConsoleCommand("lastinv")
	end
end

function SWEP:Initialize()
	util.PrecacheSound("weapons/c4_initiate.wav")
end

if SERVER then

	local function RandomatSpeedLiveJump()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "50% More Speed, Jump Power and Life for everyone!")
		for k,v in pairs(player.GetAll()) do
			local nexthealth = v:Health() * 1.5
			v:SetHealth( nexthealth )
			v:SetMaxHealth( nexthealth )
			v:SetJumpPower( v:GetJumpPower() + 80)
			if v:Health() <= 30 then
				v:SetHealth(50)
			end
		end
		hook.Add("TTTPlayerSpeed", "RandomatTTTSpeed" , function(ply)
				return 1.5
		end )
		hook.Add("TTTPrepareRound", "RandomatTTTSpeed", function()
				for k,v in pairs(player.GetAll()) do
					v:SetJumpPower( 160 )
				end
				hook.Remove("TTTPlayerSpeed", "RandomatTTTSpeed")
				hook.Remove("TTTPrepareRound", "RandomatTTTSpeed")
			end)
	end

	local function RandomatDeathmatch()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "Random Team Deathmatch!")
		local Players = {}
		for k,v in RandomPairs(util.GetAlivePlayers()) do
			table.insert(Players,v)
		end

		local PlayerNum = #Players
		local DetectiveNum = PlayerNum / 2

		for i = 1, PlayerNum do
			local Num = math.random(1, #Players)
			local Ply = Players[Num]

			if DetectiveNum > 0 then
				Ply:SetRole(ROLE_DETECTIVE)
				DetectiveNum = DetectiveNum - 1
			else
				Ply:SetRole(ROLE_TRAITOR)
			end
			Ply:SetDefaultCredits()
			table.remove(Players, Num)
		end
		SendFullStateUpdate()
	end

	local function GiveRandomWeapon(ply)
		if ply.rtweapontry >= 100 then return end
		ply.rtweapontry = ply.rtweapontry + 1
		local rnd = math.random(1,2)
		local tbl = rnd == 1 and table.Copy(EquipmentItems[ROLE_TRAITOR]) or table.Copy(EquipmentItems[ROLE_DETECTIVE])

		for k, v in pairs(weapons.GetList()) do
		    if v and v.CanBuy then
					table.insert(tbl, v)
				end
		end
		local item = table.Random(tbl)
		local is_item = tonumber(item.id)

		local swep_table = (!is_item) and weapons.GetStored(item.ClassName) or nil

		if is_item then
			if ply:HasEquipmentItem(is_item) then
				GiveRandomWeapon(ply)
			else
				ply:GiveEquipmentItem(is_item)
				hook.Call("TTTOrderedEquipment", GAMEMODE, ply, is_item, is_item)
				net.Start("RandomatFixClientSideWeapons")
				net.WriteBit(true)
				net.WriteInt(is_item, 16)
				net.Send(ply)
			end
		elseif swep_table then
			if ply:CanCarryWeapon(swep_table) then
				ply:Give(item.ClassName)
				hook.Call("TTTOrderedEquipment", GAMEMODE, ply, item.ClassName, is_item)
				net.Start("RandomatFixClientSideWeapons")
				net.WriteBit(false)
				net.WriteString(item.ClassName)
				net.Send(ply)
				if swep_table.WasBought then
					 swep_table:WasBought(ply)
				end
			else
				GiveRandomWeapon(ply)
			end
		end
	end

	local function RandomatItem()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "What did I find in my pocket?")
		for k,ply in pairs(util.GetAlivePlayers()) do
			ply.rtweapontry = 1
			GiveRandomWeapon(ply)
		end
	end

	local function RandomatRegeneration()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "We learned how to heal overself, its hard, but definitely possible over time...")
		for key,ply in pairs(player.GetAll()) do
			ply.Rmdregeneration = CurTime() + 1
		end
		hook.Add("Think", "RandomatRegeneration", function()

			local alive = util.GetAlivePlayers()
			local num = #alive

			for i = 1, num do
				local ply = alive[i]
				if ply.Rmdregeneration <= CurTime() then
					ply:SetHealth(math.Clamp(ply:Health() + 1,0,100))
					ply.Rmdregeneration = CurTime() + 1
				end
			end
		end)
		hook.Add("EntityTakeDamage", "RandomatRegeneration", function(victim, dmg )
			if victim:IsPlayer() and victim:IsTerror() and dmg:GetDamage() < victim:Health() then
				victim.Rmdregeneration = CurTime() + 10
			end
		end)
		hook.Add("TTTPrepareRound", "HookSuddenDeathRemove", function()
				hook.Remove("EntityTakeDamage", "RandomatRegeneration")
				hook.Remove("Think", "RandomatRegeneration")
				hook.Remove("TTTPrepareRound", "HookSuddenDeathRemove")
			end)
	end

	local function RandomatFreeforAll()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "Free for all!")
		for key,ply in pairs(util.GetAlivePlayers()) do
			if ply:GetRole() == ROLE_TRAITOR or (ply.GetEvil and ply:GetEvil()) then
				ply:GiveEquipmentItem(EQUIP_RADAR)
				ply:SendLua([[RunConsoleCommand("ttt_radar_scan")]])
				timer.Simple(0.1, function()
						ply:Give("weapon_ttt_knife")
						ply:Give("weapon_ttt_push")
					end )
			elseif ply:GetRole() == ROLE_DETECTIVE then
				ply:GiveEquipmentItem(EQUIP_RADAR)
				ply:SendLua([[RunConsoleCommand("ttt_radar_scan")]])
				timer.Simple(0.1, function()
						ply:Give("weapon_ttt_push")
						ply:Give("weapon_ttt_knife")
					end )
			elseif ply:GetRole() == ROLE_INNOCENT or (ply.IsNeutral and ply:IsNeutral()) then
				timer.Simple(0.1, function()
						ply:Give("weapon_ttt_push")
						ply:Give("weapon_ttt_knife")
					end )
			end
		end
	end

	local function RandomatMoonGravity()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "What? Moon Gravity on Earth?")
		for key,ply in pairs(util.GetAlivePlayers()) do
			ply:SetGravity(0.1)
		end
		timer.Create("RandomatGravity", 1, 0, function()
				for key,ply in pairs(player.GetAll()) do
					if ply:GetGravity() ~= 0.1 then
						ply:SetGravity(0.1)
					end
				end
			end )
		hook.Add("TTTPrepareRound", "RandomatGravity", function()
			for key,ply in pairs(player.GetAll()) do
				ply:SetGravity(1)
			end
			timer.Remove("RandomatGravity")
			hook.Remove("TTTPrepareRound", "RandomatGravity")
		end)
	end

	local function RandomatFlash()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "Everything is as fast as Flash now!(50% faster)")
		game.SetTimeScale(1.5)
		hook.Add("TTTPrepareRound", "RandomatTimescale", function()
			game.SetTimeScale(1)
			hook.Remove("TTTPrepareRound", "RandomatTimescale")
		end)
	end

	local function RandomatModels()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "Watch the models of choosen ones whisly, they say the truth!(In 20 Seconds)")
		timer.Create("TTTRandomatModels", 10, 1, function()
				RandomatBroadcast("Randomat: ", Color(255,255,255), "The Models of the choosen ones have been revealed!")
				local Players = {}
				for key,v in RandomPairs(util.GetAlivePlayers()) do
					if !v:GetDetective() then
						table.insert(Players,v)
					end
				end

				local PlayerNum = #Players
				local ModelNum = PlayerNum / 3

				for k, ply in RandomPairs(Players) do
					if ModelNum > 0 then
						ModelNum = ModelNum - 1
						ply.Modelchanged = true
						if ply:GetRole() == ROLE_INNOCENT or (ply.IsNeutral and ply:IsNeutral()) then
							ply:SetModel("models/player/mossman.mdl")
						elseif ply:GetTraitor() or (ply.GetEvil and ply:GetEvil()) then
							ply:SetModel("models/player/skeleton.mdl")
						end
					end
					table.remove(Players, Num)
				end
			end )
		hook.Add("PlayerSpawn", "RandomatModelFix", function(ply)
				timer.Simple(0.1, function()
					if IsValid(ply) and ply.Modelchanged then
						if ply:GetRole() == ROLE_INNOCENT or (ply.IsNeutral and ply:IsNeutral()) then
							ply:SetModel("models/player/mossman.mdl")
						elseif ply:GetTraitor() then
							ply:SetModel("models/player/skeleton.mdl")
						end
					end
				end)
		end)
		hook.Add("TTTPrepareRound", "RandomatModel", function()
			for k,v in pairs(player.GetAll()) do
				if v.Modelchanged then
					v.Modelchanged = false
				end
			end
			timer.Remove("TTTRandomatModels")
			hook.Remove("PlayerSpawn", "RandomatModelFix")
			hook.Remove("TTTPrepareRound", "RandomatModel")
		end)
	end

	local function RandomatDisguise()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "WHO IS WHO? I cant seem to remember...")
		net.Start("RandomatOverrideTargetID")
		net.Broadcast()
	end

	local function RandomatExplode()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "A Random Person will explode in 30 seconds! Watch out! (EXCEPT DETECTIVES)")
		local effectdata = EffectData()
		timer.Create("RandomatExplode", 30, 1, function()
				local aliveplayer = {}
				for k,v in pairs(util.GetAlivePlayers()) do
					if !v:GetDetective() then
						table.insert(aliveplayer,v)
					end
				end
				local randomply = aliveplayer[math.random(#aliveplayer)]
				if IsValid(randomply) then
					RandomatBroadcast("Randomat: ", Color(255,255,255), randomply:Nick() .. " exploded!")
					randomply:EmitSound( Sound ("ambient/explosions/explode_4.wav") )
					util.BlastDamage( randomply, randomply, randomply:GetPos() , 300 , 10000 )
					effectdata:SetStart( randomply:GetPos() + Vector(0,0,10) )
					effectdata:SetOrigin( randomply:GetPos() + Vector(0,0,10) )
					effectdata:SetScale( 1 )
					util.Effect( "HelicopterMegaBomb", effectdata )
				else
					RandomatBroadcast("Randomat: ", Color(255,255,255), "No one found to Explode!")
				end
			end )
		hook.Add("TTTEndRound", "RandomatExplode", function()
			timer.Remove("RandomatExplode")
			hook.Remove("TTTEndRound", "RandomatExplode")
			hook.Remove("TTTPrepareRound", "RandomatExplode")
		end)
		hook.Add("TTTPrepareRound", "RandomatExplode", function()
			timer.Remove("RandomatExplode")
			hook.Remove("TTTEndRound", "RandomatExplode")
			hook.Remove("TTTPrepareRound", "RandomatExplode")
		end)
	end

	local function RandomatTime()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "It can hurt, but it also can heal...")
		timer.Create("RandomatLive",2,0, function()
				for k,v in pairs(util.GetAlivePlayers()) do
					local rdm = math.random(1,2)
					local rdmhealth = math.random(1,5)
					local nexthealth = 100
					if rdm == 1 then
						nexthealth = v:Health() + rdmhealth
					else
						nexthealth = v:Health() - rdmhealth
					end
					v:SetHealth(nexthealth)
					if nexthealth > v:GetMaxHealth() then
						v:SetMaxHealth(nexthealth)
					end
					if v:Health() <= 0 then
						local dmg = DamageInfo()
						dmg:SetAttacker(v)
						dmg:SetDamage(100)
						dmg:SetDamageType(DMG_GENERIC)
						v:TakeDamageInfo(dmg)
					end
				end
			end )
		hook.Add("TTTEndRound", "RandomatHookLive", function()
			timer.Remove("RandomatLive")
			hook.Remove("TTTEndRound", "RandomatHookLive")
			hook.Remove("TTTPrepareRound", "RandomatHookLive")
		end)
		hook.Add("TTTPrepareRound", "RandomatHookLive", function()
			timer.Remove("RandomatLive")
			hook.Remove("TTTEndRound", "RandomatHookLive")
			hook.Remove("TTTPrepareRound", "RandomatHookLive")
		end)
	end

	local function RandomatRandomWeapons()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "Try your best...")
		for key,v in pairs(util.GetAlivePlayers()) do
			for k, weapon in pairs(v:GetWeapons()) do
				if weapon.Kind == WEAPON_HEAVY or weapon.Kind == WEAPON_PISTOL then
					v:StripWeapon(weapon:GetClass())
				end
			end
		end

		 local tbl1 = {}
		 local tbl2 = {}
			for k, wep in RandomPairs(weapons.GetList()) do
				if wep.AutoSpawnable and wep.Kind == WEAPON_HEAVY then
					table.insert(tbl1, wep)
				end
				if wep.AutoSpawnable and wep.Kind == WEAPON_PISTOL then
					table.insert(tbl2, wep)
				end
			end
		for key,p in pairs(util.GetAlivePlayers()) do
			local randomweapon = table.Random(tbl1)
			local randomweapon2 = table.Random(tbl2)
			p:Give(randomweapon.ClassName)
			p:Give(randomweapon2.ClassName)
			p:GetWeapon(randomweapon.ClassName).AllowDrop = false
			p:GetWeapon(randomweapon2.ClassName).AllowDrop = false
		end
		hook.Add("TTTPrepareRound", "TTTRandomatItems", function()
			timer.Remove("RandomItems")
			hook.Remove("TTTPrepareRound", "TTTRandomatItems")
		end)
	end

	local function RandomatLifeSteal()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "Gaining life for killing people? Is it really worth it...")
		hook.Add("PlayerDeath", "RandomatLifeSteal", function(victim, inflictor, attacker)
				attacker:SetHealth(attacker:Health() + 25)
		end)
		hook.Add("TTTPrepareRound", "RandomatLifeSteal", function()
			hook.Remove("PlayerDeath", "RandomatLifeSteal")
			hook.Remove("TTTPrepareRound", "RandomatLifeSteal")
		end)
	end

	local function RandomatDamageTimer()
		local delay = math.random(5, 15)
		timer.Create("RandomatDamageTimer", delay, 1, function()
			local rdmp = table.Random(util.GetAlivePlayers())
			local dmg = DamageInfo()
			dmg:SetAttacker(rdmp)
			dmg:SetDamage(math.random(10,50))
			dmg:SetDamageType(DMG_GENERIC)
			rdmp:TakeDamageInfo(dmg)
			hook.Remove("TTTPrepareRound", "RandomatDamageTimer")
			RandomatDamageTimer()
		end)
		hook.Add("TTTPrepareRound", "RandomatDamageTimer", function()
			timer.Remove("RandomatDamageTimer")
			hook.Remove("TTTPrepareRound", "RandomatDamageTimer")
		end)
	end

	local function RandomatRdmDmg()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "Watch out, every second could be your last!")
		RandomatDamageTimer()
	end

	local function RandomatFalldamage()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "No more Falldamage!")
		NofalldamageRandomat = true
		hook.Add("EntityTakeDamage", "TTTRandomatFall", function(ent, dmginfo)
				if IsValid(ent) and ent:IsPlayer() and dmginfo:IsFallDamage() then
					return true
				end
			end)
		  hook.Add("TTTPrepareRound", "TTTRandomatFall", function()
			hook.Remove("EntityTakeDamage", "TTTRandomatFall")
			hook.Remove("TTTPrepareRound", "TTTRandomatFall")
		end)
	end

	local function RandomatExplosion()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "No more Explosion Damage!")
		NoexplosiondamageRandomat = true
		hook.Add("EntityTakeDamage", "TTTRandomatExplode", function(ent, dmginfo)
				if IsValid(ent) and ent:IsPlayer() and dmginfo:IsExplosionDamage() then
					return true
				end
			end)
		hook.Add("TTTPrepareRound", "TTTRandomatExplode", function()
			hook.Remove("EntityTakeDamage", "TTTRandomatExplode")
			hook.Remove("TTTPrepareRound", "TTTRandomatExplode")
		end)
	end

	local function RandomatRandomHealth()
		RandomatBroadcast("Randomat: ", Color(255,255,255),"Random Health for everyone!")
		for k,v in pairs(util.GetAlivePlayers()) do
			local randomhealth = math.random(0,100)
				v:SetHealth(v:Health() + randomhealth)
			if v:Health() > v:GetMaxHealth() then
				v:SetMaxHealth(v:Health())
			end
		end
	end

	local function RandomatRoles()
		RandomatBroadcast("Randomat: ", Color(255,255,255), "ROLE SHUFFLE!")
		SelectRoles()
		SendFullStateUpdate()
		for k,ply in pairs(util.GetAlivePlayers()) do
			for l,wep in pairs(ply:GetWeapons()) do
				if wep.Kind == WEAPON_ROLE then
					ply:StripWeapon(wep:GetClass())
				end
			end
			hook.Call("PlayerLoadout", GAMEMODE, ply)
		end
	end

	local function RandomatInvertTimer(bool)
		local delay = math.random(5, 20)
		timer.Create("RandomatInvertTimer", delay, 1, function()
			if bool then
				hook.Remove("SetupMove", "RandomatInvertEverything")
				hook.Remove("TTTPrepareRound", "RandomatInvert")
				net.Start("RandomatHooks1")
				net.WriteBool(false)
				net.Broadcast()
				RandomatInvertTimer(false)
			else
				hook.Add("SetupMove", "RandomatInvertEverything", function(ply, mv, cmd)
					if ply:IsTerror() then
						local forwardspeed = mv:GetForwardSpeed()
						local sidespeed = mv:GetSideSpeed()
						mv:SetForwardSpeed( -forwardspeed )
						mv:SetSideSpeed( -sidespeed )
					end
				end)
				hook.Add("TTTPrepareRound", "RandomatInvert", function()
					hook.Remove("SetupMove", "RandomatInvertEverything")
					hook.Remove("TTTPrepareRound", "RandomatInvert")
				end)
				net.Start("RandomatHooks1")
				net.WriteBool(true)
				net.Broadcast()
				RandomatInvertTimer(true)
			end
		end)
	end

	local function RandomatInvert()
		RandomatBroadcast("Randomat: ", COLOR_WHITE, "Maybe you should look at your controls.")

		hook.Add("SetupMove", "RandomatInvertEverything", function(ply, mv, cmd)
				if ply:IsTerror() then
					local forwardspeed = mv:GetForwardSpeed()
					local sidespeed = mv:GetSideSpeed()
					mv:SetForwardSpeed( -forwardspeed )
					mv:SetSideSpeed( -sidespeed )
				end
			end)
		hook.Add("TTTPrepareRound", "RandomatInvertEverything", function()
			hook.Remove("SetupMove", "RandomatInvertEverything")
			hook.Remove("TTTPrepareRound", "RandomatInvertEverything")
		end)
		net.Start("RandomatHooks1")
		net.WriteBool(true)
		net.Broadcast()
		RandomatInvertTimer(true)
		hook.Add("TTTPrepareRound", "RandomatInvertTimerRemove", function()
			timer.Remove("RandomatInvertTimer")
			hook.Remove("TTTPrepareRound", "RandomatInvertTimerRemove")
		end)
	end

	local function RandomatSideWaysTimer(bool)
		local delay = math.random(5, 10)
		timer.Create("RandomatSideWaysTimer", delay, 1, function()
			if bool then
				hook.Remove("SetupMove", "RandomatSideWays")
				hook.Remove("TTTPrepareRound", "RandomatSideWays")
				net.Start("RandomatHooks2")
				net.WriteBool(false)
				net.Broadcast()
				RandomatSideWaysTimer(false)
			else
				hook.Add("SetupMove", "RandomatSideWays", function(ply, mv, cmd)
					if ply:IsTerror() then
						mv:SetForwardSpeed( 0 )
					end
				end )
				hook.Add("TTTPrepareRound", "RandomatSideWays", function()
					hook.Remove("SetupMove", "RandomatSideWays")
					hook.Remove("TTTPrepareRound", "RandomatSideWays")
				end)
				net.Start("RandomatHooks2")
				net.WriteBool(true)
				net.Broadcast()
				RandomatSideWaysTimer(true)
			end
		end)
	end

	local function RandomatSideWays()
		RandomatBroadcast("Randomat: ", COLOR_WHITE, "Only Sideways allowed!.")
		hook.Add("SetupMove", "RandomatSideWays", function(ply, mv, cmd)
			if ply:IsTerror() then
				mv:SetForwardSpeed( 0 )
			end
		end )
		hook.Add("TTTPrepareRound", "RandomatSideWays", function()
			hook.Remove("SetupMove", "RandomatSideWays")
			hook.Remove("TTTPrepareRound", "RandomatSideWays")
		end)
		RandomatSideWaysTimer(true)
		net.Start("RandomatHooks2")
		net.WriteBool(true)
		net.Broadcast()
		hook.Add("TTTPrepareRound", "RandomatSideWaysTimerRemove", function()
			timer.Remove("RandomatSideWaysTimer")
			hook.Remove("TTTPrepareRound", "RandomatSideWaysTimerRemove")
		end)
	end

		-- global for a reason
		RandomatRandomEvents = {
			RandomatRoles,
			RandomatFalldamage,
			RandomatFreeforAll,
			RandomatMoonGravity,
			RandomatDeathmatch,
			RandomatRandomHealth,
			RandomatSuperBlitz,
			RandomatFlash,
			RandomatModels,
			RandomatDisguise,
			RandomatSpeedLiveJump,
			RandomatExplode,
			RandomatExplosion,
			RandomatTime,
			RandomatLifeSteal,
			RandomatRandomWeapons,
			RandomatSideWays,
			RandomatItem,
			RandomatRdmDmg,
			RandomatRegeneration,
			RandomatInvert
		}

	function SWEP:PrimaryAttack()
		table.Shuffle(RandomatRandomEvents)
		local position = math.random(1,#RandomatRandomEvents)
		local Event = RandomatRandomEvents[position]
		Event()
		table.remove(RandomatRandomEvents, position)
		if #RandomatRandomEvents == 0 then
				RandomatRandomEvents = {
					RandomatRoles,
					RandomatFalldamage,
					RandomatFreeforAll,
					RandomatMoonGravity,
					RandomatDeathmatch,
					RandomatRandomHealth,
					RandomatSuperBlitz,
					RandomatFlash,
					RandomatModels,
					RandomatDisguise,
					RandomatSpeedLiveJump,
					RandomatExplode,
					RandomatExplosion,
					RandomatTime,
					RandomatLifeSteal,
					RandomatRandomWeapons,
					RandomatSideWays,
					RandomatItem,
					RandomatRdmDmg,
					RandomatRegeneration,
					RandomatInvert
			}
		end
		DamageLog("RANDOMAT: " .. self.Owner:Nick() .. " [" .. self.Owner:GetRoleString() .. "] used his Randomat" )
		self:SetNextPrimaryFire(CurTime() + 10)
		self:Remove()
	end

end

if CLIENT then
	net.Receive("RandomatHooks1",function()
			local bool = net.ReadBool()
			if bool then
				hook.Add("SetupMove", "RandomatInvertEverything", function(ply, mv, cmd)
						if ply:IsTerror() then
							local forwardspeed = mv:GetForwardSpeed()
							local sidespeed = mv:GetSideSpeed()
							mv:SetForwardSpeed( -forwardspeed )
							mv:SetSideSpeed( -sidespeed )
						end
				end)
				hook.Add("TTTPrepareRound", "RandomatInvertEverything", function()
					hook.Remove("SetupMove", "RandomatInvertEverything")
					hook.Remove("TTTPrepareRound", "RandomatInvertEverything")
				end)
			else
				hook.Remove("SetupMove", "RandomatInvertEverything")
				hook.Remove("TTTPrepareRound", "RandomatInvertEverything")
			end
		end)
	net.Receive("RandomatHooks2",function()
			local bool = net.ReadBool()
			if bool then
				hook.Add("SetupMove", "RandomatSideWays", function(ply, mv, cmd)
						if ply:IsTerror() then
							mv:SetForwardSpeed( 0 )
						end
					end )
				hook.Add("TTTPrepareRound", "RandomatSideWays", function()
					hook.Remove("SetupMove", "RandomatSideWays")
					hook.Remove("TTTPrepareRound", "RandomatSideWays")
				end)
			else
				hook.Remove("SetupMove", "RandomatSideWays")
				hook.Remove("TTTPrepareRound", "RandomatSideWays")
			end
		end)
	net.Receive("RandomatOverrideTargetID",function()
			hook.Add("HUDDrawTargetID", "RandomatOverrideTargetID", function()
					local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)
					local ent = trace.Entity
					if IsValid(ent) and IsPlayer(ent) then
						return true
					end
				end )
				hook.Add("TTTPrepareRound", "RandomatOverrideTargetID", function()
					hook.Remove("HUDDrawTargetID", "RandomatOverrideTargetID")
					hook.Remove("TTTPrepareRound", "RandomatOverrideTargetID")
				end)
		end )
		net.Receive("RandomatFixClientSideWeapons",function()
			local is_item = net.ReadBit() == 1
			local id = is_item and net.ReadUInt(16) or net.ReadString()
			hook.Run("TTTBoughtItem", is_item, id)
		end)
end

-- Old Functions

-- local function RandomatTitans()
-- 	RandomatBroadcast("Randomat: ", Color(255,255,255), "The fight of the Titans!")
-- 	for key,ply in pairs(util.GetAlivePlayers()) do
-- 		ply:SetHealth(ply:Health() + 200)
-- 		ply:SetMaxHealth(ply:GetMaxHealth() + 200)
-- 	end
-- end

-- local function RandomatRotateTimer()
-- 	for k,ply in pairs(util.GetAlivePlayers()) do
		-- local delay = math.random(2, 10)
		-- timer.Create("RandomatRotateTimer", delay, 1, function()
		-- 	if IsValid(ply) then
		-- 		ply:SetEyeAngles(ply:EyeAngles() + Angle(0,math.random(90,360),0))
		-- 	end
		-- 	hook.Remove("TTTPrepareRound", "RandomatRotateTimer")
		-- 	RandomatRotateTimer()
		-- end)
		-- hook.Add("TTTPrepareRound", "RandomatRotateTimer", function()
		-- 	timer.Remove("RandomatRotateTimer")
		-- 	hook.Remove("TTTPrepareRound", "RandomatRotateTimer")
		-- end)
-- 	end
-- end
--
-- local function RandomatRotate()
-- 	RandomatBroadcast("Randomat: ", Color(255,255,255), "Rotate in another way!")
-- 	RandomatRotateTimer()
-- end

-- local function RandomatJump()
--   RandomatBroadcast("Randomat: ", Color(255,255,255), "Jumping is fun, so a few people can now jump higher! Sadly its the other way around for the rest.")
--   for k,v in pairs(player.GetAll()) do
--     local randomatjump = math.random(1,2)
--     if randomatjump == 1 then
--       v:SetJumpPower(459)
--     elseif randomatjump == 2 then
--       v:SetJumpPower(0)
--     end
--   end
	-- hook.Add("TTTPrepareRound", "RandomatJump", function()
	-- 	for k,v in pairs(player.GetAll()) do
	-- 		v:SetJumpPower(160)
	-- 	end
	-- 	hook.Remove("TTTPrepareRound", "RandomatJump")
	-- end)
-- end

-- local function RandomatSuddenDeath()
--   RandomatBroadcast("Randomat: ", Color(255,255,255), "Sudden DEATH!! AND NOBODY CAN HEAL!(Except Detectives)")
--   for key,ply in pairs(util.GetAlivePlayers()) do
--     if !ply:GetDetective() then
--       ply:SetHealth(1)
--       ply:SetMaxHealth(1)
--     end
--   end
--   timer.Create("SuddenDeathHealRandomat", 1, 0, function()
--       for k,v in pairs(util.GetAlivePlayers()) do
--         if v:Health() > 1 and !v:GetDetective() then
--           v:SetHealth(1)
--         end
--       end
--     end )
--   hook.Add("TTTPrepareRound", "HookSuddenDeathRemove", function()
--       timer.Remove("SuddenDeathHealRandomat")
--       hook.Remove("TTTPrepareRound", "HookSuddenDeathRemove")
--     end)
-- end

-- local function RandomatBullet()
--   RandomatBroadcast("Randomat: ", Color(255,255,255), "Only Weapons allowed!")
--   NoBulletdamageRandomat = true
--   hook.Add("EntityTakeDamage", "TTTRandomatBullet", function(ent, dmginfo)
--       if IsValid(ent) and ent:IsPlayer() and !dmginfo:IsBulletDamage() and !dmginfo:GetDamageType(DMG_FALL) then
--         return true
--       end
--     end)
--   hook.Add("TTTPrepareRound", "TTTRandomatBullet", function()
--     hook.Remove("EntityTakeDamage", "TTTRandomatBullet")
--     hook.Remove("TTTPrepareRound", "TTTRandomatBullet")
--   end)
-- end

	/*local function RandomatScreenFlip()
		RandomatBroadcast("Randomat: ", COLOR_WHITE, "Flipping your Screen UPSIDE DOWN!")
		for k,ply in pairs(util.GetAlivePlayers()) do
			local Ang = ply:EyeAngles()
			if Ang.z != 180 then
				ply:SetEyeAngles( Angle( Ang.x, Ang.y, 180 ) )
			end
		end
		timer.Create("RandomatFlipScreen",1,0, function()
			for k,ply in pairs(util.GetAlivePlayers()) do
				local Ang = ply:EyeAngles()
				if Ang.z != 180 then
					ply:SetEyeAngles( Angle( Ang.x, Ang.y, 180 ) )
				end
			end
		end)
		hook.Add("TTTEndRound", "UndoRandomatFlipScreen", function()
			for k,ply in pairs(util.GetAlivePlayers()) do
				local Ang = ply:EyeAngles()
				ply:SetEyeAngles( Angle( Ang.x, Ang.y, 0 ) )
			end
			timer.Remove("RandomatFlipScreen")
			hook.Remove("TTTEndRound", "UndoRandomatFlipScreen")
			hook.Remove("TTTPrepareRound", "UndoRandomatFlipScreen")
		end)
		hook.Add("TTTPrepareRound", "UndoRandomatFlipScreen", function()
			for k,ply in pairs(util.GetAlivePlayers()) do
				local Ang = ply:EyeAngles()
				ply:SetEyeAngles( Angle( Ang.x, Ang.y, 0 ) )
			end
			timer.Remove("RandomatFlipScreen")
			hook.Remove("TTTPrepareRound", "UndoRandomatFlipScreen")
		end)
	end*/

/*local function RandomatHuge()
	RandomatBroadcast("Randomat: ", Color(255,255,255), "Let it SPRAY! You are not able to drop this weapon and you get Infinite Ammo!")
	for key,ply in pairs(util.GetAlivePlayers()) do
		for k,v in pairs(ply:GetWeapons()) do
			if v.Kind == WEAPON_HEAVY then
				ply:StripWeapon( v:GetClass() )
				ply:Give("weapon_zm_sledge")
				timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_sledge") ply:GetWeapon( "weapon_zm_sledge" ).AllowDrop = false end )
			else
				ply:Give("weapon_zm_sledge")
				timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_sledge") ply:GetWeapon( "weapon_zm_sledge" ).AllowDrop = false end )
			end
		end
	end
	timer.Create("UnlimitedRandomatHuge", 0.5, 0, function()
			for key,ply in pairs(util.GetAlivePlayers()) do
				if !ply:HasWeapon("weapon_zm_sledge") then
					ply:Give("weapon_zm_sledge")
				else
					ply:GetWeapon( "weapon_zm_sledge" ):SetClip1( 150 )
				end
			end
		end )
	hook.Add("TTTPrepareRound", "UnlimitedRandomatHuge", function()
			timer.Remove("UnlimitedRandomatHuge")
			hook.Remove("TTTPrepareRound", "UnlimitedRandomatHuge")
		end)
end*/

/*local function RandomatBurn()
RandomatBroadcast("Randomat: ", Color(255,255,255), "Burn for the detectives my little friends, BURN FOR OUR LIFE!!")
	for key,ply in pairs(util.GetAlivePlayers()) do
		if ply:GetRole() == ROLE_INNOCENT then
			ply:Ignite( math.random(1,5) )
		elseif ply:GetRole() == ROLE_TRAITOR then
			ply:Ignite( math.random(2,6) )
		elseif ply:GetRole() == ROLE_DETECTIVE then
			local randomhealth = ply:Health() + math.random(20,50)
			ply:SetHealth( randomhealth)
			ply:SetMaxHealth(randomhealth)
		end
	end
end*/

-- local function RandomatSuperBlitz()
--   RandomatBroadcast("Randomat: ", Color(255,255,255), "TTT-SuperVote, 400% More Speed!")
--   hook.Remove("TTTPlayerSpeed", "RandomatTTTSpeed" )
--   hook.Add("TTTPlayerSpeed", "RandomatTTTSuperSpeed" , function(p)
--         return 4
--     end )
--   hook.Add("TTTPrepareRound", "RandomatTTTSuperSpeed", function()
--     hook.Remove("TTTPlayerSpeed", "RandomatTTTSuperSpeed")
--     hook.Remove("TTTPrepareRound", "RandomatTTTSuperSpeed")
--   end)
-- end

/*local function RandomatJackpot()
NodamageJackpot = true
NodamageJackpot2 = true
RandomatBroadcast(Color(255,255,255), "Jackpot!(You should be happy now :D ) No more Explosion and Falldamage, 200 HP, higher Jumping more Speed and Low Gravity! And Tiny People and Knifes! What could be better?")
for k,v in pairs(util.GetAlivePlayers()) do
	v:SetModelScale( 0.5, 1 )
	v:SetHealth(200)
	v:SetJumpPower(320)
	v.RandomatJackpotSpeed = true
	v:Give("weapon_ttt_push")
	v:Give("weapon_ttt_knife")
	v:SetGravity(0.1)
end
hook.Add("EntityTakeDamage", "TTTRandomatJackpot", function(ent, dmginfo)
		if NodamageJackpot == true and IsValid(ent) and ent:IsPlayer() and dmginfo:IsFallDamage() then
			return true
		end
	end )
hook.Add("EntityTakeDamage", "TTTRandomatJackpot2", function(ent, dmginfo)
		if NodamageJackpot2 == true and IsValid(ent) and ent:IsPlayer() and dmginfo:IsExplosionDamage() then
			return true
		end
	end )
hook.Add("TTTPlayerSpeed", "RandomatTTTJackpotSpeed" , function(ply)
		if ply.RandomatJackpotSpeed == true then
			return 2
		end
	end )
for key,ply in pairs(util.GetAlivePlayers()) do
	for k,v in pairs(ply:GetWeapons()) do
		if v.Kind == WEAPON_HEAVY then
			ply:StripWeapon( v:GetClass() )
			ply:Give("weapon_zm_shotgun")
			timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_shotgun") end )
		elseif v.Kind == WEAPON_PISTOL then
			ply:StripWeapon( v:GetClass() )
			ply:Give("weapon_zm_revolver")
		else
			ply:Give("weapon_zm_shotgun")
			ply:Give("weapon_zm_revolver")
			timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_shotgun") end )
		end
	end
end
end*/

/*local function RandomatTinyRats()
RandomatBroadcast(Color(255,255,255), "You wanne be tiny like rats? Now you are!")
for k,v in pairs(util.GetAlivePlayers()) do
	v:SetModelScale( 0.5, 1 )
end
end*/

/* local function RandomatFreeWeapons()
RandomatBroadcast(Color(255,255,255), "Free Weapons! You are not able to drop these weapons!")
for key,ply in pairs(util.GetAlivePlayers()) do
	for k,v in pairs(ply:GetWeapons()) do
		if v.Kind == WEAPON_HEAVY then
			ply:StripWeapon( v:GetClass() )
			ply:Give("weapon_zm_shotgun")
			timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_shotgun") end )
		elseif v.Kind == WEAPON_PISTOL then
			ply:StripWeapon( v:GetClass() )
			ply:Give("weapon_zm_revolver")
		else
			ply:Give("weapon_zm_shotgun")
			ply:Give("weapon_zm_revolver")
			timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_shotgun") end )
		end
	end
end
timer.Simple(0.2, function()
		for key,ply in pairs(util.GetAlivePlayers()) do
			for k,v in pairs(ply:GetWeapons()) do
				if v.Kind == WEAPON_HEAVY or v.Kind == WEAPON_PISTOL then
					v.AllowDrop = false
				end
			end
		end
	end )
end */

/*local function RandomatSecretWeapons()
RandomatBroadcast(Color(255,255,255), "Show me your Secret Weapons my FRIEND 8) !")
for key,ply in pairs(util.GetAlivePlayers()) do
	for k,v in pairs(ply:GetWeapons()) do
		if v.Kind == WEAPON_EQUIP1 then
			ply:SelectWeapon( v:GetClass() )
		elseif v.Kind == WEAPON_EQUIP2 then
			ply:SelectWeapon( v:GetClass() )
		else
			ply:Give("weapon_ttt_knife")
			ply:SelectWeapon( "weapon_ttt_knife")
		end
	end
end
end*/

/*local function RandomatAmmo()
RandomatBroadcast(Color(255,255,255), "WITH WHAT YOU WANT TO SHOOT NOW?")
for key,ply in pairs(util.GetAlivePlayers()) do
	for i, weapon in pairs(ply:GetWeapons()) do
		if (weapon.Primary.ClipSize != -1) and weapon.Kind == WEAPON_HEAVY then
			weapon:SetClip1(0)
		elseif (weapon.Primary.ClipSize != -1) and weapon.Kind == WEAPON_PISTOL then
			weapon:SetClip1(0)
		end
		if (weapon.Secondary.ClipSize != -1) and weapon.Kind == WEAPON_HEAVY then
			weapon:SetClip2(0)
		elseif (weapon.Secondary.ClipSize != -1) and weapon.Kind == WEAPON_PISTOL then
			weapon:SetClip2(0)
		end
	end
end
end*/

/*local function RandomatWeapons()
RandomatBroadcast(Color(255,255,255), "Oh NO! Where are my Weapons D:!")
for key,ply in pairs(util.GetAlivePlayers()) do
	for k,v in pairs(ply:GetWeapons()) do
		if v.Kind == WEAPON_HEAVY or v.Kind == WEAPON_EQUIP1 or v.Kind == WEAPON_EQUIP2 or v.Kind == WEAPON_PISTOL or v.Kind == WEAPON_ROLE then
			ply:StripWeapon( v:GetClass() )
			timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_improvised") end )
		end
	end
end
end*/

/* local function RandomatCamping()
RandomatBroadcast(Color(255,255,255), "ONLY CAMPING 8) You are not able to drop these weapons!")
for key,ply in pairs(util.GetAlivePlayers()) do
	for k,v in pairs(ply:GetWeapons()) do
		if v.Kind == WEAPON_HEAVY then
			ply:StripWeapon( v:GetClass() )
			ply:Give("weapon_zm_rifle")
			timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_rifle") end )
		elseif v.Kind == WEAPON_PISTOL then
			ply:StripWeapon( v:GetClass() )
			ply:Give("weapon_zm_revolver")
		else
			ply:Give("weapon_zm_rifle")
			ply:Give("weapon_zm_revolver")
			timer.Simple( 0.1, function() ply:SelectWeapon("weapon_zm_rifle") end )
		end
	end
end
timer.Simple(0.2, function()
		for key,ply in pairs(util.GetAlivePlayers()) do
			for k,v in pairs(ply:GetWeapons()) do
				if v.Kind == WEAPON_HEAVY or v.Kind == WEAPON_PISTOL then
					v.AllowDrop = false
				end
			end
		end
	end )
end */

/*local function RandomatRelaxed()
RandomatBroadcast(Color(255,255,255), "Take it relaxed!")
game.SetTimeScale(0.75)
hook.Add("TTTPrepareRound", "RandomatSetTimescaleRelaxed", function()
		game.SetTimeScale(1)
	end )
end*/
