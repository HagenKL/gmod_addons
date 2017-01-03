local detectiveEnabled = CreateConVar("ttt_satm_detective", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Detectives be able to buy the SATM?")
local traitorEnabled = CreateConVar("ttt_satm_traitor", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Traitors be able to buy the SATM?")
local satmduration = CreateConVar("ttt_satm_duration", 10, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long the duration of the SATM should be?")


//GeneralSettings\\
SWEP.Base				= "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = !detectiveEnabled:GetBool() and !traitorEnabled:GetBool()
SWEP.HoldType = "normal"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = !detectiveEnabled:GetBool() and !traitorEnabled:GetBool() and WEAPON_NADE or WEAPON_EQUIP2


//Serverside\\
if SERVER then
	AddCSLuaFile( "shared.lua" )
	resource.AddFile("materials/VGUI/ttt/icon_satm.vmt")
	resource.AddFile("sound/weapons/satm/sm_enter.wav")
	resource.AddFile("sound/weapons/satm/sm_exit.wav")
	resource.AddWorkshop("671603913")
	util.AddNetworkString( "SATMStartSound" )
	util.AddNetworkString( "SATMEndSound" )
	local PLAYER = FindMetaTable("Player")
	util.AddNetworkString( "ColoredMessage" )
	function BroadcastMsg(...)
		local args = {...}
		net.Start("ColoredMessage")
		net.WriteTable(args)
		net.Broadcast()
	end

	function PLAYER:PlayerMsg(...)
		local args = {...}
		net.Start("ColoredMessage")
		net.WriteTable(args)
		net.Send(self)
	end
end

//Clientside\\
if CLIENT then

   SWEP.PrintName    = "SATM"
   SWEP.Slot         = 7

   SWEP.ViewModelFOV  = 70
   SWEP.ViewModelFlip = false

      SWEP.Icon = "VGUI/ttt/icon_satm"
      SWEP.EquipMenuData = {
      type = "weapon",
      desc = "The Space and Time-Manipulator! Short SATM!\nWith Leftclick you make everything faster. \nWith Rightclick you make everything slower. \nWith Reload you set everything back how it was."
   };
   net.Receive("ColoredMessage",function(len)
	local msg = net.ReadTable()
	chat.AddText(unpack(msg))
	chat.PlaySound()
   end)

end

//Damage\\
SWEP.Primary.Recoil      = 0
SWEP.Primary.Automatic   = false
SWEP.Primary.Damage      = 0
SWEP.Primary.Cone        = 0.001
SWEP.Primary.ClipSize    = 10
SWEP.Primary.ClipMax     = 10
SWEP.Primary.DefaultClip = 10
SWEP.Secondary.ClipSize	 = -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Ammo		 = ""



//Verschiedenes\\
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.UseHands = false
SWEP.CanBuy = {}
if (detectiveEnabled:GetBool()) then
	table.insert(SWEP.CanBuy, ROLE_DETECTIVE)
end
if (traitorEnabled:GetBool()) then
	table.insert(SWEP.CanBuy, ROLE_TRAITOR)
end
SWEP.LimitedStock = true

//Sounds/Models\\
SWEP.ViewModel	= "models/weapons/gamefreak/v_buddyfinder.mdl"
SWEP.WorldModel	= ""
SWEP.Weight = 5

function SWEP:Initialize()
	self.satmactive = false
	self:SetHoldType("normal")
end

function SWEP:PrimaryAttack()
	if self:Clip1() <= 0 then return end
	self.Weapon:SetNextPrimaryFire(CurTime()+(satmduration:GetInt()*1.5))
	self.Weapon:SetNextSecondaryFire(CurTime()+(satmduration:GetInt()*1.5))
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	timer.Remove("SatmActive")
	timer.Create("SatmActive", 3, 1, function()
		self.satmactive = true
	end)
	timer.Simple(0.5,function() if IsValid(self) then self.Weapon:SendWeaponAnim(ACT_VM_IDLE) end end)
	if SERVER then
		game.SetTimeScale(1.5)
		net.Start("SATMStartSound")
		net.Broadcast()
		timer.Create("ResetFast", satmduration:GetInt()*1.5, 1, function() game.SetTimeScale(1) self.satmactive = false net.Start("SATMEndSound") net.Broadcast() end )
	end
	self.Weapon:TakePrimaryAmmo(1)
end

function SWEP:SecondaryAttack()
	if self:Clip1() <= 0 then return end
	self.Weapon:SetNextPrimaryFire(CurTime()+(satmduration:GetInt()*0.5))
	self.Weapon:SetNextSecondaryFire(CurTime()+(satmduration:GetInt()*0.5))
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	timer.Remove("SatmActive")
	timer.Create("SatmActive", 1, 1, function()
		self.satmactive = true
	end)
	timer.Simple(0.5,function() if IsValid(self) then self.Weapon:SendWeaponAnim(ACT_VM_IDLE) end end)
	if SERVER then
		game.SetTimeScale(0.5)
		net.Start("SATMStartSound")
		net.Broadcast()
		timer.Create("ResetSlow", satmduration:GetInt()*0.5 , 1, function() game.SetTimeScale(1) self.satmactive = false net.Start("SATMEndSound") net.Broadcast() end )
	end
	self.Weapon:TakePrimaryAmmo(1)
end

function SWEP:Reload()
	if self:Clip1() <= 0 then return end
	if self.satmactive then
		self.satmactive = false
		self.Weapon:SetNextPrimaryFire(CurTime()+0.1)
		self.Weapon:SetNextSecondaryFire(CurTime()+0.1)
		self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		timer.Simple(0.5,function() self.Weapon:SendWeaponAnim(ACT_VM_IDLE) end)
		if SERVER then
			game.SetTimeScale(1)
			net.Start("SATMEndSound") net.Broadcast()
			timer.Remove("SatmActive")
			timer.Remove("ResetSlow")
			timer.Remove("ResetFast")
		end
	end
end



function SWEP:OnDrop()
	BroadcastMsg("SATM: ", Color(255,255,255),"The Space and Time-Manipulator was destroyed and the time is back to normal again!")
	if SERVER then
		game.SetTimeScale(1)
		self:Remove()
	end
end

if SERVER then
hook.Add("TTTPrepareRound", "ResetFast", function() game.SetTimeScale(1) timer.Remove("ResetFast") timer.Remove("ResetSlow")  timer.Remove("SatmActive") end )
else
	net.Receive("SATMStartSound", function()
		surface.PlaySound("weapons/satm/sm_enter.wav")
	end)
	net.Receive("SATMEndSound", function()
		surface.PlaySound("weapons/satm/sm_exit.wav")
	end)
end
