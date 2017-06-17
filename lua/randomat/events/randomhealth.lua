local EVENT = {}

EVENT.Title = "Random Health for everyone!"

function EVENT:Begin()
	for _, ply in pairs(self:GetPlayers(true)) do
		local newhealth = ply:Health() + math.random(0, 100)

		ply:SetHealth(newhealth)

		if ply:Health() > ply:GetMaxHealth() then
			ply:SetMaxHealth(newhealth)
		end
	end
end

Randomat:register("randomhealth", EVENT)
