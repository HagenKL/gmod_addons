local EVENT = {}

EVENT.Title = "Watch out, every second could be your last!"
EVENT.Time = 180

function EVENT:Begin()
	self:Timing()
end

function EVENT:Timing()
	timer.Create("RandomatDamageTimer", math.random(5,15), 1, function()
		local ply = table.Random(self:GetPlayers(true))
		local dmg = DamageInfo()

		dmg:SetAttacker(ply)
		dmg:SetDamage(math.random(10,50))
		dmg:SetDamageType(DMG_GENERIC)

		ply:TakeDamageInfo(dmg)
		self:Timing()
	end)
end

function EVENT:End()
	self:CleanUpHooks()

	timer.Remove("RandomatDamageTimer")
end

Randomat:register("randomdamage", EVENT)
