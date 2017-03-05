if SERVER then
  AddCSLuaFile()
  resource.AddFile("models/frenchie/bulkytotem.mdl")
  resource.AddFile("materials/frenchie/bulkytotem/ed3555af.vmt")
  resource.AddFile("materials/frenchie/bulkytotem/a4c3dbeb.vmt")
  resource.AddFile("materials/frenchie/bulkytotem/6348b211.vmt")
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Model = Model("models/frenchie/bulkytotem.mdl")
ENT.CanUseKey = true
ENT.CanPickup = true

function ENT:Initialize()
  self:SetModel(self.Model)
  self:SetModelScale(0.1,0)
  if SERVER then
    self:PhysicsInit(SOLID_VPHYSICS)
  end

  self:SetMoveType(MOVETYPE_NONE)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)


  if SERVER then
    self:SetMaxHealth(100)
    self:SetUseType(SIMPLE_USE)
    if self:GetOwner():IsValid() and self:GetOwner():GetNWInt("PercentCounter",0) >= 100 then
      net.Start("TTTPercentAddHalos")
      net.WriteEntity(self)
      net.Broadcast()
    end
  end

  self:SetHealth(self:GetOwner():GetNWInt("VoteBeaconHealth",100))

end

function ENT:UseOverride(activator)
  if IsValid(activator) and activator:IsTerror() and self:GetOwner() == activator then
    activator:SetNWBool("CanSpawnVoteBeacon",true)
    activator:SetNWBool("PlacedBeacon", false)
    activator:SetNWInt("VoteBeaconHealth",self:Health())
      net.Start("TTTPercentBeacon")
      net.WriteFloat(4)
      net.Send(activator)
    self:Remove()
  end
end

local zapsound = Sound("npc/assassin/ball_zap1.wav")
function ENT:OnTakeDamage(dmginfo)
  if GetRoundState() != ROUND_ACTIVE then return end
  if dmginfo:GetInflictor() == self:GetOwner() or dmginfo:GetAttacker() == self:GetOwner() then return end
  self:TakePhysicsDamage(dmginfo)

  self:SetHealth(self:Health() - dmginfo:GetDamage())
  if self:Health() <= 0 then
    self:Remove()

    if SERVER and self:GetOwner():IsValid() and self:GetOwner():GetNWInt("PercentCounter",0) >= 100 then
      net.Start("TTTPercentRemoveHalos")
      net.WriteEntity(self)
      net.Broadcast()
    end

    if SERVER and self:GetOwner():IsValid() and dmginfo:GetAttacker():IsValid() and dmginfo:GetAttacker():IsPlayer() then
      net.Start("TTTPercentBeacon")
      net.WriteFloat(5)
      net.WriteEntity(self:GetOwner())
      net.WriteEntity(dmginfo:GetAttacker())
      net.Send(self:GetOwner())
    end

    local effect = EffectData()
    effect:SetOrigin(self:GetPos())
    util.Effect("cball_explode", effect)
    sound.Play(zapsound, self:GetPos())
  end
end

if CLIENT then
  hook.Add("HUDDrawTargetID", "DrawVoteBeacon", function()
    local e = LocalPlayer():GetEyeTrace().Entity
    if IsValid(e) and e:GetClass() == "ttt_votebeacon" then
      draw.SimpleText( e:GetOwner():Nick() .. "'s Beacon", "TargetID", ScrW() / 2.0 + 1, ScrH() / 2.0 + 41, COLOR_BLACK,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
      draw.SimpleText(e:GetOwner():Nick() .. "'s Beacon","TargetID",ScrW() / 2.0, ScrH() / 2.0 + 40,Color( 255, 255, 255, 255 ),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
      local _, color = util.HealthToString(e:Health(),e:GetMaxHealth())
      draw.SimpleText(e:Health() .. " HP ","TargetIDSmall2",ScrW() / 2.0 + 1,ScrH() / 2.0 + 61,COLOR_BLACK,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
      draw.SimpleText(e:Health() .. " HP ","TargetIDSmall2",ScrW() / 2.0,ScrH() / 2.0 + 60,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
  end)
end
