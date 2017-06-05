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
  local phys = self:GetPhysicsObject()
  if (phys:IsValid()) then
    phys:Wake()
    phys:EnableDrag(true)
    phys:EnableMotion(false)
  end
end

function ENT:Explode()
  local effectdata = EffectData()
  effectdata:SetAngles(self:GetAngles())
  effectdata:SetOrigin(self:GetPos())
  local effectdata2 = EffectData()
  effectdata2:SetOrigin(self:GetPos())
  self:EmitSound("ambient/explosions/explode_4.wav",100,100)
  util.Effect("ThumperDust",effectdata)
  util.Effect("Explosion",effectdata2)
  util.BlastDamage(self, self.Owner, self:GetPos(), 150, 200 )
  self:Remove()
  local Bombs = ents.FindInSphere(self:GetPos(),120)
  for k, v in pairs(Bombs) do
    if v:GetClass() == "entity_doorbuster" and v != self then v:Explode() end
  end
end

function ENT:BlowDoor()
  self:Explode()
  for k, v in pairs(ents.FindInSphere(self:GetPos(),80)) do
    if (v:GetClass() == "prop_door_rotating" || v:GetClass() == "func_door_rotating" || v:GetClass() == "func_door") then

      local door = ents.Create("prop_physics")
      door:SetModel(v:GetModel())
      local pos = v:GetPos()
      pos:Add(self:GetAngles():Up() * -13)

      door:SetPos(pos)
      door:SetAngles(v:GetAngles())
      if isnumber(v:GetSkin()) then
        door:SetSkin(v:GetSkin())
      end
      if isstring(v:GetMaterial()) then
        door:SetMaterial(v:GetMaterial())
      end

      v:Fire("Open")
      v.DoorBusterEnt = nil
      v:Remove()
      door:Spawn()
      door:SetOwner(self.Owner)
      door:SetDamageOwner(self.Owner)
      local phys = door:GetPhysicsObject()
      phys:ApplyForceOffset((self:GetAngles():Up() * -10000) * phys:GetMass(), self:GetPos())
    end
  end
end

function ENT:OnTakeDamage(dmginfo)
  if dmginfo:GetAttacker() == self.Owner then return end
  if dmginfo:IsBulletDamage() || dmginfo:GetDamageType() == DMG_CLUB then
    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() <= 0 then
      self:BlowDoor()
    end
  end
end
