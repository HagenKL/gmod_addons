AddCSLuaFile( "shared.lua" )

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
SWEP.ViewModel = "models/hoff/animations/perks/staminup/stam.mdl"
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

SWEP.PrintName = "Stamin-Up"
SWEP.Slot = 9
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

function SWEP:DrinkTheBottle()
  net.Start("DrinkingtheStaminup")
  net.Send(self.Owner)
  timer.Simple(0.5,function()
      if self.Owner:IsTerror() then
        self:EmitSound("hoff/animations/perks/017f11fa.wav")
        self.Owner:ViewPunch( Angle( -1, 1, 0 ) )
        timer.Simple(0.8,function()
            if self.Owner:IsTerror() then
              self:EmitSound("hoff/animations/perks/0180acfa.wav")
              self.Owner:ViewPunch( Angle( -2.5, 0, 0 ) )
              timer.Simple(1,function()
                  if self.Owner:IsTerror() then
                    self:EmitSound("hoff/animations/perks/017c99be.wav")
                    timer.Simple(0.8,function()
                        if self.Owner:IsTerror() then
                          self:EmitSound("hoff/animations/perks/017bf9c0.wav")
                          self.Owner:SetNWBool("StaminUpActive",true)
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

hook.Add("TTTPrepareRound", "TTTStaminupReset", function()
    for k,v in pairs(player.GetAll()) do
      v:SetNWBool("StaminUpActive",false)
    end
  end)

hook.Add("DoPlayerDeath", "TTTStaminupReset",function(ply)
    if ply:HasEquipmentItem(EQUIP_STAMINUP) then
      ply:SetNWBool("StaminUpActive",false)
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
  net.Receive("DrinkingtheStaminup", function()
      surface.PlaySound("hoff/animations/perks/buy_stam.wav")
    end)
end

hook.Add("TTTPlayerSpeed", "StaminUpSpeed", function(ply)
    if ply:GetNWBool("StaminUpActive",false) and ply:HasEquipmentItem(EQUIP_STAMINUP) then
      return 2
    end
  end)
