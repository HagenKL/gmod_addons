local EVENT = {}

EVENT.Title = "Random Team Deathmatch"

function EVENT:Begin()
	for i, ply in pairs(self:GetAlivePlayers(true)) do
		if (i % 2) == 0 then
			ply:SetRole( ROLE_DETECTIVE )
		else
			ply:SetRole( ROLE_TRAITOR )
		end
		ply:SetDefaultCredits()
	end
	SendFullStateUpdate()
end

Randomat:register("deathmatch", EVENT)
