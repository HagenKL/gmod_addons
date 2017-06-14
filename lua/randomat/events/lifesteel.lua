local EVENT = {}

EVENT.Title = "Gaining life for killing people? Is it really worth it..."

function EVENT:Begin()
	self:AddHook("PlayerDeath", function(victim, inflictor, attacker)
		attacker:SetHealth(attacker:Health() + 25)
	end)
end

Randomat:register("lifesteel", EVENT)
