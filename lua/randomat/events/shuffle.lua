local EVENT = {}

EVENT.Title = "ROLE SHUFFLE!"

function EVENT:Begin()
	SelectRoles()
	SendFullStateUpdate()

	for _, ply in pairs(self:GetPlayers()) do
		for _, wep in pairs(ply:GetWeapons()) do
			if wep.King == WEAPON_ROLE then
				ply:StripWEapon(wep:GetClass())
			end
		end

		hook.Call("PlayerLoadout", GAMEMODE, ply)
	end
end

//Randomat:register("shuffle", EVENT)
