if SERVER then
  AddCSLuaFile( "shared.lua" )
  util.AddNetworkString("SpeedBlurHUD")
  resource.AddFile("sound/perks/buy_speed.wav")
  resource.AddFile("models/weapons/c_perk_bottle.mdl")
  resource.AddFile("materials/models/perk_bottle/c_perk_bottle_speed.vmt")
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

SWEP.PrintName = "Speed Cola"
SWEP.Slot = 9
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModelFlip = false
SWEP.DeploySpeed = 4
SWEP.UseHands = true

function SWEP:DrinkTheBottle()
  if !self.Owner:HasEquipmentItem(EQUIP_SPEED) then
    if CLIENT then
      hook.Run("TTTBoughtItem", EQUIP_SPEED, EQUIP_SPEED)
    else
      self.Owner:GiveEquipmentItem(EQUIP_SPEED)
    end
  end
  if SERVER then
    self.Owner:SelectWeapon(self:GetClass())
    net.Start("DrinkingtheSpeed")
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
                    net.Start("SpeedBlurHUD")
                    net.Send(self.Owner)
                    timer.Create("TTTSpeed" .. self.Owner:EntIndex(),0.8, 1,function()
                        if IsValid(self) and self.Owner:IsTerror() then
                          self:EmitSound("perks/burp.wav")
                          self.Owner:SetNWBool("SpeedActive",true)
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

function SWEP:OnDrop()
  if IsValid(self) then
    self:Remove()
  end
end

function ApplySpeed(wep)
  if (wep.Kind == WEAPON_HEAVY or wep.Kind == WEAPON_PISTOL) then
    wep:SetDeploySpeed(2)
    if wep.AmmoEnt != "item_box_buckshot_ttt" then
      wep.OldReload = wep.Reload
      wep.Reload = function( self, ... )
        if ( self:Clip1() == self.Primary.ClipSize or self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 ) or self.Reloading then return end
        if !IsFirstTimePredicted() then return end
        timer.Remove("SpeedReload" .. self:EntIndex())
        local ct = CurTime()
        self.Reloading = true
        self:SendWeaponAnim(ACT_VM_RELOAD)
        local sequencetime = self:SequenceDuration()
        diff = sequencetime/2 + ct
        self.reloadtimer = diff
        self:SetPlaybackRate(2)
        self.Owner:GetViewModel():SetPlaybackRate(2)
        self:SetNextPrimaryFire(diff)
        self:SetNextSecondaryFire(diff)
        self.Owner:SetFOV(0,0.2)
        self:SetIronsights( false )
      end
      wep.OldThink = wep.Think
      wep.Think = function( self, ...)
        if IsValid(self) and self.Reloading and IsFirstTimePredicted() and self.reloadtimer <= CurTime() and
        IsValid(self.Owner) and self.Owner:IsTerror() and self.Owner:GetActiveWeapon() == self then
          local maxclip = self.Primary.ClipSize
          local curclip = self:Clip1()
          local amounttoreplace = math.min(maxclip-curclip,self.Owner:GetAmmoCount(self.Primary.Ammo))
          self:SetClip1(curclip + amounttoreplace)
          self.Owner:RemoveAmmo(amounttoreplace, self.Primary.Ammo)
          self.Reloading = false
        end
      end
      wep.OldOnDrop = wep.OnDrop
      wep.OnDrop = function( self, ...)
        if IsValid(self) then
          self:SetDeploySpeed(1)
          self.Reloading = false
          self.Reload = self.OldReload
          self.Think = self.OldThink
          self.OnDrop = self.OldOnDrop
          self.OldReload = nil
          self.OldOnDrop = nil
          self.OldThink = nil
        end
      end
    elseif wep.AmmoEnt == "item_box_buckshot_ttt" then
      wep.OldStartReload = wep.StartReload
      wep.OldPerformReload = wep.PerformReload
      wep.OldFinishReload = wep.FinishReload
      wep.StartReload = function( self, ...)
        if self.dt.reloading then
          return false
        end

        self:SetIronsights( false )

        if !IsFirstTimePredicted() then return false end

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
        self:SetPlaybackRate(2)
        self.Owner:GetViewModel():SetPlaybackRate(2)
        self.reloadtimer = CurTime() + wep:SequenceDuration()/2

        --wep:SetNWBool("reloading", true)
        self.dt.reloading = true

        return true
      end
      wep.PerformReload = function(self, ...)
        local ply = self.Owner

        -- prevent normal shooting in between reloads
        self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

        if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end

        if self:Clip1() >= self.Primary.ClipSize then return end

        self.Owner:RemoveAmmo( 1, self.Primary.Ammo, false )
        self:SetClip1( self:Clip1() + 1 )

        self:SendWeaponAnim(ACT_VM_RELOAD)
        self:SetPlaybackRate(2)
        self.Owner:GetViewModel():SetPlaybackRate(2)

        self.reloadtimer = CurTime() + self:SequenceDuration()/2
      end
      wep.FinishReload = function( self, ...)
        self.dt.reloading = false

        self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
        self:SetPlaybackRate(2)
        self.Owner:GetViewModel():SetPlaybackRate(2)

        self.reloadtimer = CurTime() + self:SequenceDuration()/2
      end
      wep.OldOnDrop = wep.OnDrop
      wep.OnDrop = function( self, ...)
        self.Reloading = false
        self:SetDeploySpeed(1)
        self.StartReload = self.OldStartReload
        self.PerformReload = self.OldPerformReload
        self.FinishReload = self.OldFinishReload
        self.OnDrop = self.OldOnDrop
        self.OldStartReload = nil
        self.OldPerformReload = nil
        self.OldFinishReload = nil
        self.OldOnDrop = nil
      end
    end
  end
end

function RemoveSpeed(wep)
  if (wep.Kind == WEAPON_HEAVY or wep.Kind == WEAPON_PISTOL) then
    wep:SetDeploySpeed(1)
    wep.Reloading = false
    if wep.AmmoEnt != "item_box_buckshot_ttt" then
      wep.Reload = wep.OldReload
      wep.Think = wep.OldThink
      wep.OnDrop = wep.OldOnDrop
      wep.OldReload = nil
      wep.OldOnDrop = nil
      wep.OldThink = nil
    elseif wep.AmmoEnt == "item_box_buckshot_ttt" then
      wep.StartReload = wep.OldStartReload
      wep.PerformReload = wep.OldPerformReload
      wep.FinishReload = wep.OldFinishReload
      wep.OnDrop = wep.OldOnDrop
      wep.OldStartReload = nil
      wep.OldPerformReload = nil
      wep.OldFinishReload = nil
      wep.OldOnDrop = nil
    end
  end
end

hook.Add("PlayerSwitchWeapon", "TTTSpeedEnable", function(ply, old, new)
    if ply:GetNWBool("SpeedActive",false) and ply:HasEquipmentItem(EQUIP_SPEED) then
      ApplySpeed(new)
      RemoveSpeed(old)
    end
  end)

hook.Add("TTTPrepareRound", "TTTSpeedReset", function()
    for k,v in pairs(player.GetAll()) do
      v:SetNWBool("SpeedActive",false)
      timer.Remove("TTTSpeed" .. v:EntIndex())
    end
  end)

hook.Add("DoPlayerDeath", "TTTSpeedReset",function(ply)
    if ply:HasEquipmentItem(EQUIP_SPEED) then
      ply:SetNWBool("SpeedActive",false)
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
  net.Receive("DrinkingtheSpeed", function()
      surface.PlaySound("perks/buy_speed.wav")
    end)
  net.Receive("SpeedBlurHUD", function()
      hook.Add( "HUDPaint", "SpeedBlurHUD", function()
          if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "ttt_perk_speed" then
            DrawMotionBlur(0.4, 0.8, 0.01)
          end
        end)
      timer.Simple(0.7,function() hook.Remove( "HUDPaint", "SpeedBlurHUD" ) end)
    end)
end

function SWEP:Initialize()
  if CLIENT then
    if self.Owner == LocalPlayer() and LocalPlayer().GetViewModel then
      local vm = LocalPlayer():GetViewModel()
      local mat = "models/perk_bottle/c_perk_bottle_speed"
      oldmat = vm:GetMaterial() or ""
      vm:SetMaterial(mat)
    end
  end
  timer.Simple(0, function() self:DrinkTheBottle() end)
end

function SWEP:GetViewModelPosition( pos, ang )

  local newpos = LocalPlayer():EyePos()
  local newang = LocalPlayer():EyeAngles()
  local up = newang:Up()

  newpos = newpos + LocalPlayer():GetAimVector()*3 - up*65

  return newpos, newang

end
