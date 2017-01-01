if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT_PEWarning")
else
	net.Receive("TTT_PEWarning", function()
		local idx = net.ReadUInt(16)
		local armed = net.ReadBool()

		if armed then
			local pos = net.ReadVector()
			RADAR.bombs[idx] = {pos=pos, nick="ExplodeProp"}
		else
			RADAR.bombs[idx] = nil
		end

		RADAR.bombs_count = table.Count(RADAR.bombs)
	end)
end
