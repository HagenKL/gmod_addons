

hook.Add("PostGamemodeLoaded", "TTTInitSlowmo", function()
if (GAMEMODE_NAME == "terrortown") then 
net.Receive("SlowMotion", function()
	local enabled = net.ReadUInt(1) == 1
	local validply = net.ReadUInt(1) == 1
	local ply
	if validply then
		ply = net.ReadEntity()
	end
	hook.Call("SlowMotion", GAMEMODE, ply, enabled)
end)
	
hook.Add("Initialize", "InitializeSlowMotionClient", function()

	LANG.AddToLanguage("english", "item_SlowMotion", "SlowMotion")
	LANG.AddToLanguage("english", "item_SlowMotion_desc", "A Killing Floor like SlowMotion.\nOne use only; it slows down the game for a short time. \nbind a key for 'SlowMotion' to use it.")
	LANG.AddToLanguage("english", "item_SlowMotion_once", "You can only use the SlowMotion once.")
	LANG.AddToLanguage("english", "item_SlowMotion_nobuy", "You can't use the SlowMotion because you didn't buy it.")
	LANG.AddToLanguage("english", "item_SlowMotion_role", "Your role doesn't allow using the SlowMotion.")
	
	function GAMEMODE:SlowMotion(ply, enabled)
		local str = enabled and "enter" or "exit"
		local sound = "/sm_"..str..".wav"
		surface.PlaySound(sound)
	end
	
end)
	
local function askSlowMotion()
	net.Start("SlowMotion_Ask")
	net.SendToServer()
end
	
hook.Add("PlayerBindPress", "PlayerBindPressSlowMotion", function(ply,key,pressed)
	if string.find(string.lower(key), "phys_swap") and pressed then
		askSlowMotion()
	end
end)
	
concommand.Add("SlowMotion", askSlowMotion)

end
end )