if SERVER then
  AddCSLuaFile( "shared.lua" )
  util.AddNetworkString("JuggerBlurHUD")
  resource.AddFile("sound/perks/buy_jug.wav")
  resource.AddFile("materials/models/perk_bottle/c_perk_bottle_jugg.vmt")
end

SWEP.Author = "Gamefreak"
SWEP.Instructions = "Reach for Juggernog tonight!"
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_NONE
SWEP.AmmoEnt = ""
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true
SWEP.AllowDrop = false
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.AutoSpawnable = false
SWEP.Spawnable = false
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

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "Juggernog"
SWEP.Slot = 9
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.DeploySpeed = 4
SWEP.UseHands = true

function SWEP:DrinkTheBottle()
  if !self.Owner:HasEquipmentItem(EQUIP_JUGGERNOG) then
    if CLIENT then
      hook.Run("TTTBoughtItem", EQUIP_JUGGERNOG, EQUIP_JUGGERNOG)
    else
      self.Owner:GiveEquipmentItem(EQUIP_JUGGERNOG)
    end
  end
  if SERVER then
    self.Owner:SelectWeapon(self:GetClass())
    net.Start("DrinkingtheJuggernog")
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
                    net.Start("JuggerBlurHUD")
                    net.Send(self.Owner)
                    timer.Create("TTTJuggernog" .. self.Owner:EntIndex(),0.8, 1,function()
                        if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
                          self:EmitSound("perks/burp.wav")
                          self.Owner:SetHealth(self.Owner:GetMaxHealth())
                          self.Owner:SetNWBool("JuggernogActive",true)
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
end

hook.Add("TTTPrepareRound", "TTTJuggernogResettin", function()
  for k,v in pairs(player.GetAll()) do
    v:SetNWBool("JuggernogActive",false)
    timer.Remove("TTTJuggernog" .. v:EntIndex())
  end
end)

hook.Add("DoPlayerDeath","TTTJuggernogReset", function(pl)
    if pl:HasEquipmentItem(EQUIP_JUGGERNOG) then
      pl:SetNWBool("JuggernogActive",false)
    end
  end)

hook.Add("EntityTakeDamage", "TTTJuggernogReduction", function(target, dmginfo)
  if target:IsPlayer() and target:GetNWBool("JuggernogActive",false) and target:HasEquipmentItem(EQUIP_JUGGERNOG) and (dmginfo:IsBulletDamage() or dmginfo:IsExplosionDamage()) then
    dmginfo:ScaleDamage(0.9)
  end
end)

function SWEP:OnRemove()
  if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
    RunConsoleCommand("lastinv")
  end

if CLIENT then
    if self.Owner == LocalPlayer() and LocalPlayer().GetViewModel then
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

function SWEP:OnDrop()
  if IsValid(self) then
    self:Remove()
  end
end

function SWEP:ShouldDropOnDie()
  return false
end

if CLIENT then
  net.Receive("DrinkingtheJuggernog", function()
      surface.PlaySound("perks/buy_jug.wav")
    end)

    net.Receive("JuggerBlurHUD", function()
      hook.Add( "HUDPaint", "JuggerBlurHUD", function()
        if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "ttt_perk_juggernog" then
          DrawMotionBlur(0.4, 0.8, 0.01)
        end
      end)
      timer.Simple(0.7,function() hook.Remove( "HUDPaint", "JuggerBlurHUD" ) end)
    end)
end

function SWEP:Initialize()
  timer.Simple(0.1, function()
    self:DrinkTheBottle()
    if CLIENT then
      if self.Owner == LocalPlayer() and LocalPlayer().GetViewModel then
        local vm = LocalPlayer():GetViewModel()
        local mat = "models/perk_bottle/c_perk_bottle_jugg" --perk_materials[self:GetPerk()]
        oldmat = vm:GetMaterial() or ""
        vm:SetMaterial(mat)
      end
    end
  end)
  return self.BaseClass.Initialize(self)
end

function SWEP:GetViewModelPosition( pos, ang )

 	local newpos = LocalPlayer():EyePos()
	local newang = LocalPlayer():EyeAngles()
	local up = newang:Up()

	newpos = newpos + LocalPlayer():GetAimVector()*3 - up*65

	return newpos, newang

end
