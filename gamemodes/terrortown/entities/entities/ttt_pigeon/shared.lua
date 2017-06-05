ENT.Type = "anim"
ENT.Model = Model( "models/pigeon.mdl" )

local BirdSounds = {
	"ambient/creatures/seagull_idle1.wav",
	"ambient/creatures/seagull_idle2.wav",
	"ambient/creatures/seagull_idle3.wav",
	"ambient/creatures/seagull_pain1.wav",
	"ambient/creatures/seagull_pain2.wav",
	"ambient/creatures/seagull_pain3.wav"
}


function ENT:Initialize()
	self:SetModel( self.Model )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetModelScale(2,0.01)

	if( SERVER ) then
		self:SetHealth(1)
		self:SetMaxHealth(1)
		self:GetPhysicsObject():SetMass( 1 )
		self:GetPhysicsObject():ApplyForceCenter( ( self.Target:GetShootPos() - self:GetPos() ) * Vector( 3, 3, 3 ) )
	end

	if( CLIENT ) then
      self:EmitSound( Sound( BirdSounds[ math.random( 1, #BirdSounds ) ], 100 ) )
	end
end


function ENT:Think()
	if( SERVER ) then
		if( IsValid( self.Target ) ) then
			local Mul = 3
			if( self:GetPos():Distance( self.Target:GetPos() ) < 200 ) then Mul = 15 end
			self:GetPhysicsObject():ApplyForceCenter( ( self.Target:GetShootPos() - self:GetPos() ) * Vector( Mul, Mul, Mul ) )
			self:SetAngles( ( ( self.Target:GetShootPos() - self:GetPos() ) * Vector( Mul, Mul, Mul ) ):Angle() )

			if( !self.Target:Alive() ) then
				self:Remove()
			end
		else
			self:Remove()
		end
	end
end
