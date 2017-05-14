AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.Exploded = false

function ENT:Initialize()
  self:PhysicsInit( SOLID_VPHYSICS )
  self:SetMoveType( MOVETYPE_VPHYSICS )
  self:SetSolid( SOLID_VPHYSICS )
  self:SetModel("models/weapons/w_c4_planted.mdl")
  self:SetUseType(1)
  self:SetHealth(50)
  self:SetMaxHealth(50)
  local phys = self.Entity:GetPhysicsObject()
  if (phys:IsValid()) then
    phys:Wake()
    phys:EnableDrag(true)
    phys:EnableMotion(false)
  end
end

function ENT:Explode()
  if self.Exploded then return end
  self.Exploded = true
  local effectdata = EffectData()
  effectdata:SetAngles(self.Entity:GetAngles())
  effectdata:SetOrigin(self.Entity:GetPos())
  util.Effect("ThumperDust",effectdata)
  local effectdata2 = EffectData()
  effectdata2:SetOrigin(self.Entity:GetPos())
  util.Effect("Explosion",effectdata2)
  self:EmitSound("ambient/explosions/explode_4.wav",100,100)
  util.BlastDamage(self, self.Owner, self:GetPos(), 150, 200 )
  self:Remove()
  local Bombs = ents.FindInSphere(self:GetPos(),120)
  for k, v in pairs(Bombs) do
    if v:GetClass()=="entity_doorbuster" and v != self.Entity then v:Explode() end
  end
end

function ENT:BlowDoor()
  self:Explode()
  for k, v in pairs(ents.FindInSphere(self:GetPos(),80)) do
    if (v:GetClass() == "prop_door_rotating" || v:GetClass() == "func_door_rotating" || v:GetClass() == "func_door") and not v.Exploded then
      v:SetColor(0,0,0,0)
      local door = ents.Create("prop_physics")
      door:SetModel(v:GetModel())
      local pos=v:GetPos()
      pos:Add(self.Entity:GetAngles():Up()*-13)
      door:SetPos(pos)
      door:SetAngles(v:GetAngles())
      door:SetSkin(v:GetSkin())
      door:SetMaterial(v:GetMaterial())
      door:Spawn()
      local phys = door:GetPhysicsObject()
      phys:ApplyForceOffset((self.Entity:GetAngles():Up()*-10000)*phys:GetMass(),self.Entity:GetPos())
      v:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
      v.Exploded = true
      v.DoorBusterEnt = nil
      v:Remove()
    end
  end
end

function ENT:OnTakeDamage(dmginfo)
  if dmginfo:IsBulletDamage() or dmginfo:GetDamageType() == DMG_CLUB then
    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() <= 0 then
      self:BlowDoor()
    end
  end
end
