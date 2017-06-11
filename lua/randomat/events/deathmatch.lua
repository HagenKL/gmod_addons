local EVENT = {}

EVENT.Title = "Random Team Deathmatch"
EVENT.Time = 60

function EVENT:Begin()
	for i, ply in pairs(self:GetPlayers(true)) do
		if (i % 2) == 0 then
			ply:SetRole( ROLE_DETECTIVE )
		else
			ply:SetRole( ROLE_TRAITOR )
		end
		ply:SetDefaultCredits()
	end
end

Randomat:register("deathmatch", EVENT)
