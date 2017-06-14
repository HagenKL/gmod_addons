if SERVER then
   AddCSLuaFile( "shared.lua" )
   resource.AddFile("materials/VGUI/ttt/icon_sawedoff.vmt")
   resource.AddWorkshop("630413726")
end

SWEP.HoldType                   = "shotgun"

if CLIENT then
   SWEP.PrintName = "Sawed Off"
        SWEP.ViewModelFlip = false
   SWEP.Slot = 2
   SWEP.ViewModelFOV = 70
   SWEP.Icon = "VGUI/ttt/icon_sawedoff"
end


SWEP.Base                               = "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Kind = WEAPON_HEAVY
SWEP.UseHands = true
SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Damage = 9
SWEP.Primary.Cone = 0.1
SWEP.Primary.Delay = 1
SWEP.Primary.ClipSize = 6
SWEP.Primary.ClipMax = 12
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 11
SWEP.AutoSpawnable      = true
SWEP.AmmoEnt = "item_box_buckshot_ttt"
SWEP.UseHands = true
SWEP.ViewModel                  = "models/weapons/v_sawedoff.mdl"
SWEP.WorldModel                 = "models/weapons/w_sawedoff.mdl"
SWEP.Primary.Sound                      = ( "weapons/sawedoff/sawedoff_fire.wav" )
SWEP.Primary.Recoil                     = 7
--SWEP.IronSightsPos            = Vector( 5.7, -3, 3 )
--SWEP.IronSightsPos			= Vector(-7.680, -2.951, 3.508)

SWEP.IronSightsPos = Vector(-5,1.1,3)
SWEP.IronSightsAng = Vector(0.15, 0, 0)
SWEP.SightsPos = Vector(5.738, -2.951, 3.378)
SWEP.SightsAng = Vector(0.15, 0, 0)
SWEP.RunSightsPos = Vector(0.328, -6.394, 1.475)
SWEP.RunSightsAng = Vector(-4.591, -48.197, -1.721)

SWEP.reloadtimer = 0

function SWEP:SetupDataTables()
   self:DTVar("Bool", 0, "reloading")

   return self.BaseClass.SetupDataTables(self)
end

function SWEP:Reload()

   --if self:GetNWBool( "reloading", false ) then return end
   if self.dt.reloading then return end

   if not IsFirstTimePredicted() then return end

   if self:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 then

      if self:StartReload() then
         return
      end
   end

end

function SWEP:StartReload()
   --if self:GetNWBool( "reloading", false ) then
   if self.dt.reloading then
      return false
   end

   self:SetIronsights( false )

   if not IsFirstTimePredicted() then return false end

   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   local ply = self.Owner

   if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then
      return false
   end

   local wep = self

   if wep:Clip1() >= self.Primary.ClipSize then
      return false
   end

   wep:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)

   self.reloadtimer =  CurTime() + wep:SequenceDuration()

   --wep:SetNWBool("reloading", true)
   self.dt.reloading = true

   return true
end

function SWEP:PerformReload()
   local ply = self.Owner

   -- prevent normal shooting in between reloads
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end

   if self:Clip1() >= self.Primary.ClipSize then return end

   self.Owner:RemoveAmmo( 1, self.Primary.Ammo, false )
   self:SetClip1( self:Clip1() + 1 )

   self:SendWeaponAnim(ACT_VM_RELOAD)
   if CLIENT then
     self:EmitSound("weapons/sawedoff/sawedoff_reload.wav")
   end

   self.reloadtimer = CurTime() + self:SequenceDuration()
end

function SWEP:FinishReload()
   self.dt.reloading = false
   self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)

   self.reloadtimer = CurTime() + self:SequenceDuration()
end

function SWEP:CanPrimaryAttack()
   if self:Clip1() <= 0 then
      self:EmitSound( "Weapon_Shotgun.Empty" )
      self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
      return false
   end
   return true
end

function SWEP:Think()
   if self.dt.reloading and IsFirstTimePredicted() then
      if self.Owner:KeyDown(IN_ATTACK) then
         self:FinishReload()
         return
      end

      if self.reloadtimer <= CurTime() then

         if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
            self:FinishReload()
         elseif self:Clip1() < self.Primary.ClipSize then
            self:PerformReload()
         else
            self:FinishReload()
         end
         return
      end
   end
end

function SWEP:Deploy()
   self.dt.reloading = false
   self.reloadtimer = 0
   return self.BaseClass.Deploy(self)
end

-- The shotgun's headshot damage multiplier is based on distance. The closer it
-- is, the more damage it does. This reinforces the shotgun's role as short
-- range weapon by reducing effectiveness at mid-range, where one could score
-- lucky headshots relatively easily due to the spread.
function SWEP:GetHeadshotMultiplier(victim, dmginfo)
   local att = dmginfo:GetAttacker()
   if not IsValid(att) then return 3 end

   local dist = victim:GetPos():Distance(att:GetPos())
   local d = math.max(0, dist - 140)

   -- decay from 3.1 to 1 slowly as distance increases
   return 1 + math.max(0, (2.1 - 0.002 * (d ^ 1.25)))
end

function SWEP:SecondaryAttack()
   if self.NoSights or (not self.IronSightsPos) or self.dt.reloading then return end
   --if self:GetNextSecondaryFire() > CurTime() then return end

   self:SetIronsights(not self:GetIronsights())

   self:SetNextSecondaryFire(CurTime() + 0.3)
end
