local EVENT = {}

EVENT.Title = "Watch the models of choosen ones whisly, they say the truth! (In 20 Seconds)"

function EVENT:Begin()
	timer.Simple(20, function()
		self:SmallNotify("The Models of the choosen ones have been revealed!")

		local plys = {}

		for _, ply in pairs(self:GetPlayers(true)) do
			if !v:GetDetective() then
				table.insert(plys, ply)
			end
		end

		local playernum = #plys
		local modelnum = playernum / 3

		for _, ply in RandomPairs(plys) do
			if modelnum > 0 then
				modelnum = modelnum - 1
				ply.Modelchanged = true

				if ply:GetRole() == ROLE_INNOCENT or (ply.GetJackal and ply:GetJackal()) then
					ply:SetModel("models/player/mossman.mdl")
				elseif ply:GetTraitor() or (ply.GetEvil and ply:GetEvil()) then
					ply:SetModel("models/player/skeleton.mdl")
				end
			end
		end
	end)

	self:AddHook("PlayerSpawn", function(ply)
		timer.Simple(0.1, function()
			if IsValid(ply) and ply.Modelchanged then
				if ply:GetRole() == ROLE_INNOCENT or (ply.GetJackal and ply:GetJackal()) then
					ply:SetModel("models/player/mossman.mdl")
				elseif ply:GetTraitor() or (ply.GetEvil and ply:GetEvil()) then
					ply:SetModel("models/player/skeleton.mdl")
				end
			end
		end)
	end)
end

function EVENT:End()
	self:CleanUpHooks()

	for _, ply in pairs(player.GetAll()) do
		if ply.Modelchanged then
			ply.Modelchanged = false
		end
	end
end

Randomat:register("models", EVENT)
