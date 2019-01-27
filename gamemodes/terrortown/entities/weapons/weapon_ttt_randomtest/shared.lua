if SERVER then
   AddCSLuaFile()
   util.AddNetworkString("rt result")
   util.AddNetworkString("rt started")
   util.AddNetworkString("rt notify traitor")
   util.AddNetworkString("rt failed")
   resource.AddFile("materials/VGUI/ttt/icon_randomtest.vmt")
   resource.AddWorkshop("617179823")
else
   SWEP.PrintName = "Random Tester"
   SWEP.Slot = 7

   SWEP.ViewModelFOV = 70

   SWEP.EquipMenuData = {
      type = "weapon",
      desc = "The Random Tester will randomly \npick a player and test him after 30 seconds. \n\nRight click to play Gaben."
   };

   SWEP.Icon = "vgui/ttt/icon_randomtest.vtf"
   SWEP.ViewModelFlip = false
end


function SWEP:Precache()
   util.PrecacheSound("weapons/gaben.wav")
   util.PrecacheSound("weapons/run.mp3")
end

SWEP.Author = "Gamefreak"

SWEP.Base = "weapon_tttbase"

SWEP.HoldType = "normal"

SWEP.ViewModel		= "models/weapons/gamefreak/v_wiimote_meow.mdl"
SWEP.WorldModel		= "models/weapons/gamefreak/w_wiimote_meow.mdl"

SWEP.DrawCrosshair      = false
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Sound = Sound("weapons/wiimote_meow.wav")

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Delay = 3

SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.LimitedStock = true

SWEP.AllowDrop = true
SWEP.Spawnable		= true
SWEP.AdminSpawnable	= true

SWEP.NoSights = true

local Randomtestdelay = CreateConVar("ttt_randomtest_duration", 30, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long the test should take?")

SWEP.Delay = Randomtestdelay:GetInt()
SWEP.TextDelay = 5

function SWEP:OnRemove()
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
		RunConsoleCommand("lastinv")
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
	self:EmitSound("weapons/gaben.wav",500)
end

local function GetRandomTesterPlayer()
	local result = {}
	for k,v in pairs(player.GetAll()) do
		if v:IsTerror() and (v:GetTraitor() or v:GetRole() == ROLE_INNOCENT) and !v:GetNWBool("RTTested") then
			table.insert(result,v)
		end
	end
	return result[math.random(1,#result)]
end

function SWEP:HandleMessages(ply)
	if !IsValid(ply) then net.Start("rt failed") net.Send(self.Owner) return end
	local role, nick = ply:GetRole(), ply:Nick()
	local owner, ownerNick = self.Owner, self.Owner:Nick()
	local rolestring = ply:GetRoleString()
	local id = ply:EntIndex()
	local txtDelay = self.TextDelay

	ply:SetNWBool("RTTested", true)

	if timer.Exists("RT Timer" .. id) then return end

	net.Start("rt started")
		net.WriteUInt(self.Delay,8)
	net.Broadcast()

	if (role == ROLE_TRAITOR) then
		net.Start("rt notify traitor")
			net.WriteUInt(txtDelay,8)
		net.Send(ply)
	end

	util.PrecacheSound("weapons/prank.mp3")

	timer.Create("RT Timer " .. id,self.Delay,1, function()
		if GetRoundState() != ROUND_ACTIVE then return end

		DamageLog("RTester:\t" .. ownerNick .. "[" .. owner:GetRoleString() .. "] tested " .. nick .. "[" .. rolestring .. "]")

		local valid = IsValid(ply)
		role,nick = valid and ply:GetRole() or role,valid and ply:Nick() or nick

		net.Start("rt result")
			net.WriteEntity(ply)
			net.WriteUInt(role, 4)
			net.WriteString(rolestring)
			net.WriteString(nick)
			net.WriteUInt(txtDelay,8)
		net.Broadcast()

	end)
end

local function PrintCenteredText(txt,delay,color)
	if hook.GetTable()["RT Draw Text"] then
		hook.Remove("HUDPaint","RT Draw Text")
		hook.Add("HUDPaint","RT Draw Text", function() draw.DrawText(txt,"CloseCaption_Bold",ScrW() * 0.5,ScrH() * 0.2,color,TEXT_ALIGN_CENTER) end)
		timer.Adjust("RT Remove Text",delay,1, function() hook.Remove("HUDPaint","RT Draw Text") hook.Remove("TTTEndRound","RT Remove Text") hook.Remove("TTTPrepareRound","RT Remove Text") end)
	else
		hook.Add("HUDPaint","RT Draw Text", function() draw.DrawText(txt,"CloseCaption_Bold",ScrW() * 0.5,ScrH() * 0.2,color,TEXT_ALIGN_CENTER) end)
		hook.Add("TTTEndRound","RT Remove Text", function() hook.Remove("HUDPaint","RT Draw Text") hook.Remove("TTTEndRound","RT Remove Text") hook.Remove("TTTPrepareRound","RT Remove Text") timer.Remove("RT Remove Text") end)
		hook.Add("TTTPrepareRound","RT Remove Text", function() hook.Remove("HUDPaint","RT Draw Text") hook.Remove("TTTEndRound","RT Remove Text") hook.Remove("TTTPrepareRound","RT Remove Text") timer.Remove("RT Remove Text") end)
		timer.Create("RT Remove Text",delay,1, function() hook.Remove("HUDPaint","RT Draw Text") hook.Remove("TTTEndRound","RT Remove Text") hook.Remove("TTTPrepareRound","RT Remove Text") end)
	end
end

local function GetRoleColor(role,ply)
	return !(IsValid(ply) and ply:IsTerror()) and COLOR_ORANGE or (role == ROLE_TRAITOR) and COLOR_RED or COLOR_GREEN
end

if CLIENT then
	net.Receive("rt failed", function()
		chat.AddText("Random Tester: ", COLOR_WHITE, "The Random Tester couldn't find any valid players.")
	end)

	net.Receive("rt started", function()
		chat.AddText("Random Tester: ", COLOR_WHITE, "The Random Test result will show up in " .. net.ReadUInt(8) .. " seconds!")
	end)

	net.Receive("rt notify traitor", function()
		PrintCenteredText("You have been tested! Run!!!!",net.ReadUInt(8),COLOR_RED)
		LocalPlayer():EmitSound("weapons/run.mp3")
	end)

	net.Receive("rt result", function()
		local ply, role, roleString, Nick, txtDelay, lply = net.ReadEntity(),net.ReadUInt(4),net.ReadString(),net.ReadString(),net.ReadUInt(8),LocalPlayer()
		local roleColor, textColor = GetRoleColor(role,ply), COLOR_WHITE
		local valid = IsValid(ply)
		local nick = valid and Nick or "\"" .. Nick .. "\" (unconnected)"

		if valid then
			if !(valid and ply:IsTerror()) then
				chat.AddText("Random Tester: ", roleColor,nick,textColor," was ",roleColor,roleString,textColor,"!")
				surface.PlaySound("weapons/prank.mp3")
			else
				if lply:IsTerror() then
					PrintCenteredText(nick .. " is " .. roleString .. "!",txtDelay,roleColor)
				end
			chat.AddText("Random Tester: ", roleColor,nick,textColor," is ",roleColor,roleString,textColor,"!") end
		end
		chat.PlaySound()
	end)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Delay)
	self:EmitSound("weapons/wiimote_meow.wav",500)
	if CLIENT then return end
	if GetRoundState() == ROUND_ACTIVE then
		self:HandleMessages(GetRandomTesterPlayer())
	end
	self:Remove()
end

hook.Add("TTTPrepareRound","RTReset",function()
	for k,v in pairs(player.GetAll()) do
		v:SetNWBool("RTTested", false)
	   	timer.Remove("RT Timer " .. v:EntIndex())
	end
end)
