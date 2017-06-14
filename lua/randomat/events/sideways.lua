local EVENT = {}

EVENT.Title = "Only Sideways allowed!"
EVENT.Time = 90

function EVENT:Begin()
	self:AddHook("SetupMove", function(ply, mv, cmd)
		if ply:IsTerror() then
			mv:SetForwardSpeed(0)
		end
	end)
end

Randomat:register("invert", EVENT)
