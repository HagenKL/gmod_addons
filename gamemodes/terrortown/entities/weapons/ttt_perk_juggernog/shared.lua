if SERVER then
  AddCSLuaFile( "shared.lua" )
  util.AddNetworkString("JuggerBlurHUD")
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

SWEP.ViewModel = "models/hoff/animations/perks/juggernog/jug.mdl"
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

function SWEP:DrinkTheBottle()
  net.Start("DrinkingtheJuggernog")
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
                    net.Start("JuggerBlurHUD")
                    net.Send(self.Owner)
                    timer.Create("TTTJuggernog",0.8, 1,function()
                        if IsValid(self) and IsValid(self.Owner) and self.Owner:IsTerror() then
                          self:EmitSound("hoff/animations/perks/017bf9c0.wav")
                          self.Owner:SetHealth(self.Owner:GetMaxHealth())
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
      surface.PlaySound("hoff/animations/perks/buy_jug.wav")
    end)

    net.Receive("JuggerBlurHUD", function()
      local matBlurScreen = Material( "pp/blurscreen" )
      hook.Add( "HUDPaint", "JuggerBlurHUD", function()
        if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "ttt_perk_juggernog" then
          surface.SetMaterial( matBlurScreen )
          surface.SetDrawColor( 255, 255, 255, 255 )

          matBlurScreen:SetFloat( "$blur",6 )
          render.UpdateScreenEffectTexture()

          surface.DrawTexturedRect( 0,0, ScrW(), ScrH() )

          surface.SetDrawColor( 205, 0, 0, 40 )
          surface.DrawRect( 0,0, ScrW(), ScrH() )
        end
      end)
      timer.Simple(0.7,function() hook.Remove( "HUDPaint", "JuggerBlurHUD" ) end)
    end)
end
