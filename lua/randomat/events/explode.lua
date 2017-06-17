local EVENT = {}

EVENT.Title = "A Random Person will explode in 30 seconds! Watch out! (EXCEPT DETECTIVES)"

function EVENT:Begin()
	local effectdata = EffectData()

	timer.Create("RandomatExplode",30,1, function()
		local plys = self:GetPlayers(true)
		local ply = plys[math.random(#plys)]

		if IsValid(ply) then
			self:SmallNotify(ply:Nick() .. " exploded!")
			ply:EmitSound(Sound("ambient/explosions/explode_4.wav"))

			util.BlastDamage(ply, ply, ply:GetPos(), 300, 10000)

			effectdata:SetStart(ply:GetPos() + Vector(0,0,10))
			effectdata:SetOrigin(ply:GetPos() + Vector(0,0,10))
			effectdata:SetScale(1)

			util.Effect("HelicopterMegaBomb", effectdata)
		else
			self:SmallNotify("No one exploded!")
		end
	end)
end

function EVENT:End()
	timer.Remove("RandomatExplode")
end

Randomat:register("explode", EVENT)
