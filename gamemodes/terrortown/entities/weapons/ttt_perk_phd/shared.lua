if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddFile("sound/hoff/animations/perks/buy_phd.wav")
end

SWEP.Author = "Gamefreak"
SWEP.Instructions = "Damn straight."
SWEP.Category = "CoD Zombies"
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_NONE
SWEP.AmmoEnt = ""
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true
SWEP.AllowDrop = false
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.AutoSpawnable = false
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.HoldType = "camera"

SWEP.ViewModel = "models/hoff/animations/perks/phdflopper/phd.mdl"
SWEP.WorldModel = ""

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.ViewModelFOV = 70

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "PHD Flopper"
SWEP.Slot = 9
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

function SWEP:DrinkTheBottle()
  net.Start("DrinkingthePHD")
  net.Send(self.Owner)
  timer.Simple(0.5,function()
      if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
        self:EmitSound("hoff/animations/perks/017f11fa.wav")
        self.Owner:ViewPunch( Angle( -1, 1, 0 ) )
        timer.Simple(0.8,function()
            if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
              self:EmitSound("hoff/animations/perks/0180acfa.wav")
              self.Owner:ViewPunch( Angle( -2.5, 0, 0 ) )
              timer.Simple(1,function()
                  if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
                    self:EmitSound("hoff/animations/perks/017c99be.wav")
                    timer.Create("TTTPHD",0.8, 1,function()
                        if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
                          self:EmitSound("hoff/animations/perks/017bf9c0.wav")
                          self.Owner:SetNWBool("PHDActive",true)
                          self:Remove()
                        end
                      end)
                  end
                end)
            end
          end )
      end
    end)
end

local function PHDRemoveFallDamage(target, dmginfo)
  if target:IsPlayer() and target:GetNWBool("PHDActive",false) and target:HasEquipmentItem(EQUIP_PHD) then
    if dmginfo:IsFallDamage() then
      local explode = ents.Create( "env_explosion" )
      explode:SetPos( target:GetPos() )
      explode:SetOwner( target )
      explode:Spawn()
      explode:SetKeyValue( "iMagnitude", "100" )
      explode:SetKeyValue("iRadiusOverride","256")
      explode:Fire( "Explode", 0, 0 )
      explode:EmitSound( "weapon_AWP.Single", 400, 400 )
      return true
    elseif dmginfo:IsExplosionDamage() then
      return true
    end
  end
end

hook.Add("EntityTakeDamage", "TTTPHDRemoveFallDamage", PHDRemoveFallDamage)
hook.Add("TTTPrepareRound", "TTTPHDReset", function()
    for k,v in pairs(player.GetAll()) do
      v:SetNWBool("PHDActive",false)
    end
  end)

hook.Add("DoPlayerDeath","TTTPHDReset", function(pl)
    if pl:HasEquipmentItem(EQUIP_PHD) then
      pl:SetNWBool("PHDActive",false)
    end
  end)

function SWEP:OnRemove()
  if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
    RunConsoleCommand("lastinv")
  end
end

function SWEP:Holster()
  return false
end

function SWEP:PrimaryAttack()
end

function SWEP:ShouldDropOnDie()
  return false
end

if CLIENT then
  net.Receive("DrinkingthePHD", function()
      surface.PlaySound("hoff/animations/perks/buy_phd.wav")
    end)
end
