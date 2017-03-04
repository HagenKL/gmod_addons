if SERVER then
  AddCSLuaFile()
  resource.AddFile("models/radio_reference.mdl")
  resource.AddFile("materials/models/props/radio.vmt")
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Model = Model("models/radio_reference.mdl")
ENT.CanUseKey = true
ENT.CanPickup = true

function ENT:Initialize()
  self:SetModel(self.Model)

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
    activator:SetNWInt("VoteBeaconHealth",self:Health())
    net.Start("TTTVoteBeaconPickUp")
    net.Send(activator)
    self:Remove()
  end
end

local zapsound = Sound("npc/assassin/ball_zap1.wav")
function ENT:OnTakeDamage(dmginfo)
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

    local effect = EffectData()
    effect:SetOrigin(self:GetPos())
    util.Effect("cball_explode", effect)
    sound.Play(zapsound, self:GetPos())

    if IsValid(self:GetOwner()) then
      net.Start("TTTPercentBeacon")
      net.WriteFloat(0)
      net.Send(self:GetOwner())
    end
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
