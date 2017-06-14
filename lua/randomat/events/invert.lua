local EVENT = {}

EVENT.Title = "Maybe you should look at your controls."
EVENT.Time = 120

function EVENT:Begin()
	self:AddHook("SetupMove", function(ply, mv, cmd)
		if ply:IsTerror() then
			local forwardspeed = mv:GetForwardSpeed()
			local sidespeed = mv:GetSideSpeed()

			mv:SetForwardSpeed(-forwardspeed)
			mv:SetSideSpeed(-sidespeed)
		end
	end)
end

Randomat:register("invert", EVENT)
