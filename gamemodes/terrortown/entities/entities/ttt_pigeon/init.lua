AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include( "shared.lua" )
function ENT:Explode()
	local radius = 200
	local pos = self.Entity:GetPos()

	local explosion = ents.Create("env_explosion")
	if IsValid(explosion) then
		explosion:SetPos( pos )
		explosion:Spawn()
		explosion:SetKeyValue( "iMagnitude", 600 )
		explosion:SetKeyValue( "iRadiusOverride", 400 )
		explosion:SetOwner( self.Owner )
		explosion:Fire( "Explode", 0, 0 )
	end
	self.Entity:Remove()
end


function ENT:PhysicsCollide( data, phys )
	self.Entity:Explode()
end