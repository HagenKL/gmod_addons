local EVENT = {}

EVENT.Title = "50% More Speed, Jump Power and Life for everyone!"
EVENT.Time = 120

function EVENT:Begin()
	for i, ply in pairs(self:GetAlivePlayers()) do
		local newHealth = ply:Health() * 1.5
		ply:SetHealth(newHealth)
		ply:SetMaxHealth(newHealth)
		ply:SetJumpPower(ply:GetJumpPower() + 80)

		if ply:Health() <= 30 then
			ply:SetHealth(50)
		end

		self:AddHook("TTTPlayerSpeed", function()
			return 1.5
		end)
	end
end

function EVENT:End()
	self:CleanUpHooks()

	for _, ply in pairs(player.GetAll()) do
		ply:SetJumpPower(160)
	end
end

Randomat:register("deathmatch", EVENT)
