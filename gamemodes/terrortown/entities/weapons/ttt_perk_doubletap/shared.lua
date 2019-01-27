if SERVER then
  AddCSLuaFile( "shared.lua" )
  util.AddNetworkString("DoubleTapBlurHUD")
  util.AddNetworkString("Doubletap")
    util.AddNetworkString("DrinkingtheDoubleTap")
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
  if !self.Owner:HasEquipmentItem(EQUIP_DOUBLETAP) then
    if CLIENT then
      hook.Run("TTTBoughtItem", EQUIP_DOUBLETAP, EQUIP_DOUBLETAP)
    else
      self.Owner:GiveEquipmentItem(EQUIP_DOUBLETAP)
    end
  end
  if SERVER then
    self.Owner:SelectWeapon(self:GetClass())
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
                        if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
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
end

function ApplyDoubleTap(wep)
  if (wep.Kind == WEAPON_HEAVY or wep.Kind == WEAPON_PISTOL) then
    local delay = math.Round(wep.Primary.Delay / 1.5,3)
    wep.OldDelay = wep.Primary.Delay
    wep.Primary.Delay = delay
    wep.OldOnDrop = wep.OnDrop
    wep.OnDrop = function( self, ...)
      if IsValid(self) then
        self.Primary.Delay = self.OldDelay
        self.OnDrop = self.OldOnDrop
      end
    end
    net.Start("Doubletap")
    net.WriteBool(true)
    net.WriteEntity(wep)
    net.WriteFloat(wep.Primary.Delay)
    net.WriteFloat(wep.OldDelay)
    net.Send(wep.Owner)
  end
end

function RemoveDoubleTap(wep)
  if (wep.Kind == WEAPON_HEAVY or wep.Kind == WEAPON_PISTOL) then
    wep.Primary.Delay = wep.OldDelay or wep.Primary.Delay
    wep.OnDrop = wep.OldOnDrop or wep.OnDrop
    net.Start("Doubletap")
    net.WriteBool(false)
    net.WriteEntity(wep)
    net.WriteFloat(wep.Primary.Delay)
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
    if ply:HasEquipmentItem(EQUIP_DOUBLETAP) then
      ply:SetNWBool("DoubleTapActive",false)
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

function SWEP:ShouldDropOnDie()
  return false
end

if CLIENT then
  net.Receive("DrinkingtheDoubleTap", function()
      surface.PlaySound("perks/buy_doubletap.wav")
    end)
  net.Receive("DoubleTapBlurHUD", function()
      hook.Add( "HUDPaint", "DoubleTapBlurHUD", function()
          if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "ttt_perk_doubletap" then
            DrawMotionBlur(0.4, 0.8, 0.01)
          end
        end)
      timer.Simple(0.7,function() hook.Remove( "HUDPaint", "DoubleTapBlurHUD" ) end)
    end)
end

function SWEP:Initialize()
  timer.Simple(0.1, function()
    self:DrinkTheBottle()
    if CLIENT then
      if self.Owner == LocalPlayer() and LocalPlayer().GetViewModel then
        local vm = LocalPlayer():GetViewModel()
        local mat = "models/perk_bottle/c_perk_bottle_doubletap" --perk_materials[self:GetPerk()]
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

if CLIENT then
  net.Receive("Doubletap",function()
    local apply = net.ReadBool()
    local wep = net.ReadEntity()
    wep.Primary.Delay = net.ReadFloat()
    if apply then
      wep.OldOnDrop = wep.OnDrop
      wep.OnDrop = function( self, ...)
        if IsValid(self) then
          self.Primary.Delay = net.ReadFloat()
          self.OnDrop = self.OldOnDrop
        end
      end
    else
      wep.OnDrop = wep.OldOnDrop
    end
  end )
end
