AddCSLuaFile()

// GRENADE ENTITY
// Fixed by Hds46


ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/houseburning/houseburning.mdl")

  
function ENT:Initialize()
	self:SetModel( "models/houseburning/houseburning.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self.thrown = false
end

function ENT:Explode(tr)
	if self.thrown then return end
	self:LemonExplode()
end

function ENT:PhysicsCollide( tabl, obj )
	self.thrown = true
	self:LemonExplode()
end

function ENT:LemonExplode()
	local owner = self:GetOwner()
	if self.Exploded then return end
	self.Exploded = true
	self:EmitSound( "ambient/fire/mtov_flame2.wav" )

	self:SetRenderMode( 4 )
	self:SetNoDraw(true)
	self:DrawShadow( false )
	timer.Simple(0, function() if IsValid(self) then self:SetMoveType( MOVETYPE_NONE ) end end)

	for _,b in pairs ( ents.FindInSphere(self:GetPos(),1) ) do
		if b:GetClass() == "env_sprite" and b:GetName() == "Hds46_addon_lemonade_lemsprite" then
			b:Remove()
		end
	end

	local BOOM = EffectData()
	BOOM:SetScale( 1 )


	local val = 100
	local rep = 10


	for i = 1, rep do

		timer.Simple( .1 * i, function()

			if self:IsValid() then

				for i = 1, 3 do

				   BOOM:SetOrigin( self:GetPos() + Vector( math.random( -val, val ), math.random( -val, val ), math.random( -val / 3, val / 3 ) ) )
				   util.Effect( "HelicopterMegaBomb", BOOM )

				end

				local i = math.random( 1, 2 )
				if ( i == 1 ) then
					self:EmitSound( "ambient/fire/ignite.wav" )
					elseif ( i == 2 ) then
					self:EmitSound( "ambient/fire/gascan_ignite1.wav" )
				end

				for _, ent in pairs( ents.FindInSphere( self:GetPos(), val * 2.2) ) do
				   
					if ent:IsPlayer() or ent:GetClass() == "prop_ragdoll"  then
						local dmg=DamageInfo()
						dmg:SetDamage(math.random(7,14)) 
						dmg:SetAttacker(owner)
						dmg:SetInflictor(self)
						dmg:SetDamagePosition(ent:GetPos())
						dmg:SetDamageType(DMG_BURN)
						if SERVER then
							ent:TakeDamageInfo(dmg)
						end
					end
				end
			end
		end )
		  
	end
	if SERVER then
		timer.Simple( rep * 0.12, function() self:Remove() end )
	end
end

