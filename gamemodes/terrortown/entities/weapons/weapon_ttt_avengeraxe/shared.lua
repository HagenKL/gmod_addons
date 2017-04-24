//GeneralSettings\\
SWEP.Base				= "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = true
SWEP.HoldType = "ar2"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = WEAPON_HEAVY


//Serverside\\
if SERVER then
   AddCSLuaFile( "shared.lua" )
   resource.AddFile("materials/VGUI/ttt/icon_avengeraxe.vmt")
   resource.AddWorkshop("610337130")
end

//Clientside\\
if CLIENT then

   SWEP.PrintName    = "A.X.E"
   SWEP.Slot         = 2

   SWEP.ViewModelFOV  = 70
   SWEP.ViewModelFlip = false
   SWEP.Icon = "VGUI/ttt/icon_avengeraxe"
end

//Damage\\
SWEP.Primary.Delay       = 0.1
SWEP.Primary.Recoil      = 1.75
SWEP.Primary.Automatic   = true
SWEP.Primary.NumShots = 1
SWEP.Primary.Damage      = 20
SWEP.Primary.Cone        = 0.025
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 40
SWEP.Primary.ClipMax     = 80
SWEP.Primary.DefaultClip = 40
SWEP.AmmoEnt = "item_ammo_smg1_ttt"


//Verschiedenes\\
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = true
SWEP.NoSights = false
SWEP.UseHands = true
SWEP.HeadshotMultiplier = 1.5

//Sounds/Models\\
SWEP.ViewModel	= "models/weapons/gamefreak/v_axe1_m249para.mdl"
SWEP.WorldModel	= "models/weapons/gamefreak/w_axe1_m249para.mdl"
SWEP.Weight = 5
SWEP.Primary.Sound = Sound( "weapons/gamefreak/m249/m249-1.wav" )
SWEP.IronSightsPos = Vector(-3.98,-0.83, 2.5)
SWEP.IronSightsAng = Vector(0, 0, 0)

function SWEP:SetZoom(state)
   if CLIENT then return end
   if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
   if state then
      self.Owner:SetFOV(50, 0.5)
   else
      self.Owner:SetFOV(0, 0.2)
   end
end

-- Add some zoom to ironsights for this gun
function SWEP:SecondaryAttack()
   if not self.IronSightsPos then return end
   if self.Weapon:GetNextSecondaryFire() > CurTime() then return end

   bIronsights = not self:GetIronsights()

   self:SetIronsights( bIronsights )

   if SERVER then
      self:SetZoom(bIronsights)
   end

   self.Weapon:SetNextSecondaryFire(CurTime() + 0.3)
end


function SWEP:Reload()
	if ( self:Clip1() == self.Primary.ClipSize or self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then return end

	self.Weapon:DefaultReload( ACT_VM_RELOAD );
  self:SetIronsights( false )
  self:SetZoom(false)
  if CLIENT then
    timer.Simple(0.35,function() if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self then self:EmitSound("weapons/gamefreak/m249/m249_bolt.wav") end end)
    timer.Simple(1.9,function() if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self then self:EmitSound("weapons/gamefreak/m249/m4para_charger.wav") end end)
    timer.Simple(3.3,function() if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self then self:EmitSound("weapons/gamefreak/m249/m249_boltpull.wav") end end)
    timer.Simple(4.6,function() if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self then self:EmitSound("weapons/gamefreak/m249/m249_coverdown.wav") end end)
  end
end

function SWEP:PreDrop()
   self:SetZoom(false)
   self:SetIronsights(false)
   return self.BaseClass.PreDrop(self)
end

function SWEP:Holster()
   self:SetIronsights(false)
   self:SetZoom(false)
   return true
end
