local EVENT = {}

EVENT.Title = "It can hurt, but it also can heal..."

function EVENT:Begin()
	timer.Create("RandomatLive", 2, 0, function()
		for _, ply in pairs(self:GetPlayers()) do
			local rdm = math.random(1,2)
			local rdmhealth = math.random(1,5)
			local newhealth = 100

			if rdm == 1 then
				newhealth = ply:Health() + rdmhealth
			else
				newhealth = ply:Health() - rdmhealth
			end

			ply:SetHealth(newhealth)

			if newhealth > ply:GetMaxHealth() then
				ply:SetMaxHealth(newhealth)
			end

			if ply:Health() <= 0 then
				local dmg = DamageInfo()
				dmg:SetAttacker(v)
				dmg:SetDamage(100)
				dmg:SetDamageType(DMG_GENERIC)

				ply:TakeDamageInfo(dmg)
			end
		end
	end)
end

function EVENT:End()
	timer.Remove("RandomatLive")
end

Randomat:register("live", EVENT)
