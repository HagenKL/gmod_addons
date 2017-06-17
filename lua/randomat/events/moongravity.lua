local EVENT = {}

EVENT.Title = "What? Moon Gravity on Earth?"

function EVENT:Begin()
	for _, ply in pairs(self:GetPlayers()) do
		ply:SetGravity(0.1)
	end
end

function EVENT:End()
	self:CleanUpHooks()

	for _, ply in pairs(player.GetAll()) do
		ply:SetGravity(1)
	end
end

Randomat:register("moongravity", EVENT)
