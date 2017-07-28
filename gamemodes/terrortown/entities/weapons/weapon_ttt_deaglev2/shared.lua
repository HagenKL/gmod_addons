//GeneralSettings\\
SWEP.Base = "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.HoldType = "pistol"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

//Serverside\\
if SERVER then
	AddCSLuaFile( "shared.lua" )
	resource.AddFile("materials/VGUI/ttt/icon_Deagv2.vmt")
	resource.AddWorkshop("609665987")
end

//Clientside\\
if CLIENT then

	SWEP.PrintName = "Deagle V2"
	SWEP.Slot = 7

	SWEP.ViewModelFOV = 70
	SWEP.ViewModelFlip = true

	SWEP.Icon = "VGUI/ttt/icon_Deagv2"
	SWEP.EquipMenuData = {
		type = "Weapon",
		desc = "An OP Deagle, what you want more?"
	};
end

//Damage\\
SWEP.Primary.Delay = 0.4
SWEP.Primary.Recoil = 2.1
SWEP.Primary.Automatic = true
SWEP.Primary.NumShots = 1
SWEP.Primary.Damage = 50
SWEP.Primary.Cone = 0.001
SWEP.Primary.Ammo = "Alyxgun"
SWEP.Primary.ClipSize = 16
SWEP.Primary.ClipMax = 48
SWEP.Primary.DefaultClip = 16
SWEP.AmmoEnt = "item_ammo_revolver_ttt"

//Verschiedenes\\
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.UseHands = true
SWEP.HeadshotMultiplier = 4
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = { ROLE_TRAITOR, ROLE_DETECTIVE }
SWEP.LimitedStock = true

//Sounds/Models\\
SWEP.ViewModel = "models/weapons/gamefreak/v_pist_deagv2.mdl"
SWEP.WorldModel = "models/weapons/gamefreak/w_pist_deagv2.mdl"
SWEP.Weight = 5
SWEP.Primary.Sound = Sound( "weapons/gamefreak/deagle/deagle-1.wav" )
SWEP.IronSightsPos = Vector(4.11,-0.75, 1.55)
SWEP.IronSightsAng = Vector(0, 0, 0)

function SWEP:Reload()
	if ( self:Clip1() == self.Primary.ClipSize or self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then return end

	self:DefaultReload( ACT_VM_RELOAD );

	self:SetIronsights( false )
end
