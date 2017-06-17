local EVENT = {}

EVENT.Title = "We learned how to heal overself, its hard, but definitely possible over time..."
--EVENT.Time = 180

function EVENT:Begin()
	for i, ply in pairs(self:GetAlivePlayers()) do
		ply.rmdregeneration = CurTime() + 1
	end

	self:AddHook("Think", function() self:Regeneration() end)

	self:AddHook("EntityTakeDamage", function(victim, dmg)
		if IsValid(victim) and victim:IsPlayer() and victim:IsTerror() and dmg:GetDamage() < victim:Health() then
			victim.rmdregeneration = CurTime() + 10
		end
	end)
end

function EVENT:Regeneration()
	for _, ply in pairs(self:GetAlivePlayers()) do
		if ply.rmdregeneration <= CurTime() then
			ply:SetHealth(math.Clamp(ply:Health() + 1, 0, ply:GetMaxHealth()))
			ply.rmdregeneration = CurTime() + 1
		end
	end
end

Randomat:register("regeneration", EVENT)
