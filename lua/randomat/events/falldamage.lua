local EVENT = {}

EVENT.Title = "No more Falldamage!"
--EVENT.Time = 120

function EVENT:Begin()
	self:AddHook("EntityTakeDamage", function(ent, dmginfo)
		if IsValid(ent) and ent:IsPlayer() and dmginfo:IsFallDamage() then
			return true
		end
	end)
end

Randomat:register("falldamage", EVENT)
