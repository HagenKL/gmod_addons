AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/props_lab/reciever01b.mdl")
ENT.CanUseKey = true
ENT.CanPickup = false

function ENT:Initialize()
  self:SetModel(self.Model)

  if SERVER then
    self:PhysicsInit(SOLID_VPHYSICS)
  end

  self:SetMoveType(MOVETYPE_NONE)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

  if SERVER then
    self:SetMaxHealth(100)
  end
  self:SetHealth(100)

  if SERVER then
    self:SetUseType(SIMPLE_USE)
    self:NextThink(CurTime() + 1)
    if self:GetOwner():IsValid() and self:GetOwner():GetNWInt("PercentCounter",0) >= 100 then
      net.Start("TTTPercentAddHalos")
      net.WriteEntity(self)
      net.Broadcast()
    end
  end
end

function ENT:UseOverride(activator)
  if IsValid(activator) and activator:IsTerror() and self:GetOwner() == activator then
    activator:SetNWBool("CanSpawnVoteBeacon",true)
    net.Start("TTTVoteBeaconPickUp")
    net.Send(activator)
    self:Remove()
  end
end

local zapsound = Sound("npc/assassin/ball_zap1.wav")
function ENT:OnTakeDamage(dmginfo)
  self:TakePhysicsDamage(dmginfo)

  self:SetHealth(self:Health() - dmginfo:GetDamage())
  if self:Health() < 0 then
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

--local beep = Sound("weapons/c4/c4_beep1.wav")
function ENT:Think()
  if CLIENT then
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
      dlight.Pos = self:GetPos()
      dlight.r = 255
      dlight.g = 255
      dlight.b = 255
      dlight.Brightness = 1
      dlight.Size = 256
      dlight.Decay = 500
    end

    self:NextThink(CurTime() + 5)
    return true
  end
end


if SERVER then
function ENT:UpdateTransmitState()
  return TRANSMIT_ALWAYS
end
end
