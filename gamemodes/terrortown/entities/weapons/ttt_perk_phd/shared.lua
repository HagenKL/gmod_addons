if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddFile("sound/perks/buy_phd.wav")
  util.AddNetworkString("PHDBlurHUD")
  resource.AddFile("materials/models/perk_bottle/c_perk_bottle_phd.vmt")
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

SWEP.ViewModel = "models/weapons/c_perk_bottle.mdl"
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
SWEP.ViewModelFlip = false
SWEP.DeploySpeed = 4
SWEP.UseHands = true

function SWEP:DrinkTheBottle()
  net.Start("DrinkingthePHD")
  net.Send(self.Owner)
  timer.Simple(0.5,function()
      if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
        self:EmitSound("perks/open.wav")
        self.Owner:ViewPunch( Angle( -1, 1, 0 ) )
        timer.Simple(0.8,function()
            if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
              self:EmitSound("perks/drink.wav")
              self.Owner:ViewPunch( Angle( -2.5, 0, 0 ) )
              timer.Simple(1,function()
                  if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
                    self:EmitSound("perks/smash.wav")
                    net.Start("PHDBlurHUD")
                    net.Send(self.Owner)
                    timer.Create("TTTPHD" .. self.Owner:EntIndex(),0.8, 1,function()
                        if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
                          self:EmitSound("perks/burp.wav")
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
      timer.Remove("TTTPHD" .. v:EntIndex())
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

  if CLIENT then
    if self.Owner == LocalPlayer() then
      local vm = LocalPlayer():GetViewModel()
      vm:SetMaterial(oldmat)
      oldmat = nil
    end
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
      surface.PlaySound("perks/buy_phd.wav")
    end)

    net.Receive("PHDBlurHUD", function()
      local mat = Material( "pp/blurscreen" )
      hook.Add( "HUDPaint", "PHDBlurPaint", function()
        if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "ttt_perk_phd" then
          DrawMotionBlur(0.4, 0.8, 0.01)
        end
      end)
      timer.Simple(0.7,function() hook.Remove( "HUDPaint", "PHDBlurPaint" ) end)
    end)
end

function SWEP:Initialize()
  if CLIENT then
    if self.Owner == LocalPlayer() then
      local vm = LocalPlayer():GetViewModel()
      local mat = "models/perk_bottle/c_perk_bottle_phd" --perk_materials[self:GetPerk()]
      oldmat = vm:GetMaterial() or ""
      vm:SetMaterial(mat)
    end
  end
end

function SWEP:GetViewModelPosition( pos, ang )

 	local newpos = LocalPlayer():EyePos()
	local newang = LocalPlayer():EyeAngles()
	local up = newang:Up()

	newpos = newpos + LocalPlayer():GetAimVector()*3 - up*65

	return newpos, newang

end

function SWEP:OnDrop()
  if IsValid(self) then
    self:Remove()
  end
end
