/*if SERVER then
  AddCSLuaFile( "shared.lua" )
  util.AddNetworkString("DoubleTapBlurHUD")
  util.AddNetworkString("Doubletap")
  resource.AddFile("sound/perks/buy_doubletap.wav")
  resource.AddFile("models/weapons/c_perk_bottle.mdl")
  resource.AddFile("materials/models/perk_bottle/c_perk_bottle_doubletap.vmt")
end

SWEP.Author = "Gamefreak"
SWEP.Instructions = "Oh yeah, drink it baby."
SWEP.Category = "CoD Zombies"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_NONE
SWEP.AmmoEnt = ""
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true
SWEP.AllowDrop = false
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.AutoSpawnable = false
SWEP.ViewModel = "models/weapons/c_perk_bottle.mdl"
SWEP.WorldModel = ""
SWEP.HoldType = "camera"

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

SWEP.PrintName = "DoubleTap Root Beer"
SWEP.Slot = 9
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModelFlip = false
SWEP.DeploySpeed = 4
SWEP.UseHands = true

function SWEP:DrinkTheBottle()
  net.Start("DrinkingtheDoubleTap")
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
                    net.Start("DoubleTapBlurHUD")
                    net.Send(self.Owner)
                    timer.Create("TTTDoubleTap" .. self.Owner:EntIndex(),0.8, 1,function()
                        if IsValid(self) and self.Owner:IsTerror() then
                          self:EmitSound("perks/burp.wav")
                          self.Owner:SetNWBool("DoubleTapActive",true)
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

function ApplyDoubleTap(wep)
  if (wep.Kind == WEAPON_HEAVY or wep.Kind == WEAPON_PISTOL) then
    local delay = math.Round(wep.Primary.Delay / 1.33,3)
    local numshots =  math.Round(wep.Primary.NumShots * 2,3)
    local cone =  math.Round(wep.Primary.Cone * 1.33,3)
    local recoil =  math.Round(wep.Primary.Recoil * 2,3)
    wep.OldDelay = wep.Primary.Delay
    wep.OldNumShots = wep.Primary.NumShots
    wep.OldCone = wep.Primary.Cone
    wep.OldRecoil = wep.Primary.Recoil
    wep.Primary.Delay = delay
    wep.Primary.NumShots = numshots
    wep.Primary.Cone = cone
    wep.Primary.Recoil = recoil
    wep.OldOnDrop = wep.OnDrop
    wep.OnDrop = function( self, ...)
      if IsValid(self) then
        self.Primary.Delay = self.OldDelay
        self.Primary.NumShots = self.OldNumShots
        self.Primary.Cone = self.OldCone
        self.Primary.Recoil = self.OldRecoil
        self.OnDrop = self.OldOnDrop
      end
    end
    net.Start("Doubletap")
    net.WriteBool(true)
    net.WriteEntity(wep)
    net.WriteFloat(wep.Primary.Delay)
    net.WriteFloat(wep.Primary.NumShots)
    net.WriteFloat(wep.Primary.Cone)
    net.WriteFloat(wep.Primary.Recoil)
    net.Send(wep.Owner)
  end
end

function RemoveDoubleTap(wep)
  if (wep.Kind == WEAPON_HEAVY or wep.Kind == WEAPON_PISTOL) then
    wep.Primary.Delay = wep.OldDelay
    wep.Primary.NumShots = wep.OldNumShots
    wep.Primary.Cone = wep.OldCone
    wep.Primary.Recoil = wep.OldRecoil
    wep.OnDrop = wep.OldOnDrop
    net.Start("Doubletap")
    net.WriteBool(false)
    net.WriteEntity(wep)
    net.WriteFloat(wep.Primary.Delay)
    net.WriteFloat(wep.Primary.NumShots)
    net.WriteFloat(wep.Primary.Cone)
    net.WriteFloat(wep.Primary.Recoil)
    net.Send(wep.Owner)
  end
end

function SWEP:OnDrop()
  if IsValid(self) then
    self:Remove()
  end
end

hook.Add("PlayerSwitchWeapon", "TTTDoubleTapEnable", function(ply, old, new)
    if SERVER and (ply:GetNWBool("DoubleTapActive",false) and ply:HasEquipmentItem(EQUIP_DOUBLETAP)) and (new.Kind == WEAPON_HEAVY or new.Kind == WEAPON_PISTOL) then
      ApplyDoubleTap(new)
    end
    if SERVER and (ply:GetNWBool("DoubleTapActive",false) and ply:HasEquipmentItem(EQUIP_DOUBLETAP)) and (old.Kind == WEAPON_HEAVY or old.Kind == WEAPON_PISTOL) then
      RemoveDoubleTap(old)
    end
  end)

hook.Add("TTTPrepareRound", "TTTDoubleTapReset", function()
    for k,v in pairs(player.GetAll()) do
      v:SetNWBool("DoubleTapActive",false)
      timer.Remove("TTTDoubleTap" .. v:EntIndex())
    end
  end)

hook.Add("DoPlayerDeath", "TTTDoubleTapReset",function(ply)
    if ply:HasEquipmentItem(EQUIP_doubletap) then
      ply:SetNWBool("DoubleTapActive",false)
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
  net.Receive("DrinkingtheDoubleTap", function()
      surface.PlaySound("perks/buy_doubletap.wav")
    end)
  net.Receive("DoubleTapBlurHUD", function()
      local mat = Material( "pp/blurscreen" )
      hook.Add( "HUDPaint", "DoubleTapBlurHUD", function()
          if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "ttt_perk_doubletap" then
            DrawMotionBlur(0.4, 0.8, 0.01)
          end
        end)
      timer.Simple(0.7,function() hook.Remove( "HUDPaint", "DoubleTapBlurHUD" ) end)
    end)
end

function SWEP:Initialize()
  if CLIENT then
    if self.Owner == LocalPlayer() then
      local vm = LocalPlayer():GetViewModel()
      local mat = "models/perk_bottle/c_perk_bottle_doubletap" --perk_materials[self:GetPerk()]
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

if CLIENT then
  net.Receive("Doubletap",function()
    local apply = net.ReadBool()
    local wep = net.ReadEntity()
    wep.Primary.Delay = net.ReadFloat()
    wep.Primary.NumShots = net.ReadFloat()
    wep.Primary.Cone = net.ReadFloat()
    wep.Primary.Recoil = net.ReadFloat()
    if apply then
      wep.OldOnDrop = wep.OnDrop
      wep.OnDrop = function( self, ...)
        if IsValid(self) then
          self.Primary.Delay = self.Primary.Delay * 1.33
          self.Primary.NumShots = self.Primary.NumShots / 2
          self.Primary.Cone = self.Primary.Cone / 1.33
          self.Primary.Recoil = self.Primary.Recoil / 1.33
          self.OnDrop = self.OldOnDrop
        end
      end
    else
      wep.OnDrop = wep.OldOnDrop
    end
  end )
end*/
