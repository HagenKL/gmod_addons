local EVENT = {}

EVENT.Title = "What? Moon Gravity on Earth?"

function EVENT:Begin()
	for _, ply in pairs(self:GetPlayers()) do
		ply:SetGravity(0.1)
	end
	self:Timer()
end

function EVENT:Timer()
	timer.Create("RandomatGravity", 1,0, function()
		for _, ply in pairs(self:GetPlayers()) do
			ply:SetGravity(0.1)
		end
	end)
end

function EVENT:End()
	self:CleanUpHooks()
	timer.Remove("RandomatGravity")
	for _, ply in pairs(player.GetAll()) do
		ply:SetGravity(1)
	end
end

Randomat:register("moongravity", EVENT)
