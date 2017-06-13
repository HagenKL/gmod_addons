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

  self.Exploded = true

  for k, v in pairs(ents.FindInSphere(self:GetPos(),120)) do
    if v:GetClass() == "entity_doorbuster" and v != self and !v.Exploded then v:Explode() end
  end

end

function ENT:BlowDoor()
  self:Explode()

  for k, v in pairs(ents.FindInSphere(self:GetPos(),80)) do
    if IsValid(v) and (v:GetClass() == "prop_door" or v:GetClass() == "func_door" or v:GetClass() == "prop_door_rotating" or v:GetClass() == "func_door_rotating" ) then

      local door = ents.Create("prop_physics")
      door:SetModel(v:GetModel())
      local pos = v:GetPos()
      pos:Add(self:GetAngles():Up() * -13)

      door:SetPos(pos)
      door:SetAngles(v:GetAngles())

      if v:GetSkin() then
        door:SetSkin(v:GetSkin())
      end

      door:SetMaterial(v:GetMaterial())

      v.Exploded = true
      v:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
      v:Fire("Open")
      v:Remove()

      door:SetPhysicsAttacker(self.Owner)
      door:Spawn()

      local phys = door:GetPhysicsObject()
      door:SetAngles(Angle( math.Rand( -10, 10 ), math.Rand( -10, 10 ), 0 ))
      phys:ApplyForceOffset((self:GetAngles():Up() * -10000) * phys:GetMass(), self:GetPos())
    end
  end


  self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
  if dmginfo:IsBulletDamage() || dmginfo:GetDamageType() == DMG_CLUB then
    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() <= 0 then
      self:BlowDoor()
    end
  end
end

hook.Add( "AcceptInput", "DoorBusterExplode", function( ent, input, ply, caller, value )
    if (ent:GetClass() == "prop_door" or ent:GetClass() == "func_door" or ent:GetClass() == "prop_door_rotating" or ent:GetClass() == "func_door_rotating" ) and (input == "Open" or input == "Use" or input == "Toggle") and !ent.Exploded then
        for k,v in pairs(ents.FindInSphere(ent:GetPos(),80)) do
            local owner = v.GetOwner and v:GetOwner()
            if v:GetClass() == "entity_doorbuster" and owner and ply != owner then
                v:BlowDoor()
                return true
            end
        end
    end
end)
