local EVENT = {}

EVENT.Title = "No more Explosion Damage!"
--EVENT.Time = 120

function EVENT:Begin()
	self:AddHook("EntityTakeDamage", function(ent, dmginfo)
		if IsValid(ent) and ent:IsPlayer() and dmginfo:IsExplosionDamage() then
			return true
		end
	end)
end

Randomat:register("explosion", EVENT)
