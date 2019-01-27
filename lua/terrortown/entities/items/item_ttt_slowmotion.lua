if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop( "611911370" )
	resource.AddFile("sound/slowmotion/sm_enter.wav")
	resource.AddFile("sound/slowmotion/sm_exit.wav")
	resource.AddFile("materials/VGUI/ttt/slowmotion_icon.vmt")
	resource.AddFile("materials/VGUI/ttt/slowmotion_icon.vtf")
	resource.AddFile("materials/vgui/ttt/perks/hud_slowmo.png")
	util.AddNetworkString("SlowMotionSound")
	util.AddNetworkString("SM_Ask")
	util.AddNetworkString("SMReload")
end


ITEM.hud = Material("vgui/ttt/perks/hud_slowmo.png")
ITEM.EquipMenuData = {
	type = "item_active",
	name = "item_SlowMotion",
	desc = "item_SlowMotion_desc",
}
ITEM.material = "vgui/ttt/slowmotion_icon.vmt"
ITEM.oldId = EQUIP_SM
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}
ITEM.noCorpseSearch = true


if CLIENT then

	local function askSM()
		net.Start("SM_Ask")
		net.SendToServer()
	end

	concommand.Add("SlowMotion", askSM)	


	LANG.AddToLanguage("english", "item_SlowMotion", "SlowMotion")
	LANG.AddToLanguage("english", "item_SlowMotion_desc", "A Killing Floor like SlowMotion,\nit slows down the game for a short time.\nCooldown is 45 Seconds.\nbind a key for 'SlowMotion' to use it.")
	
	local function SlowMotionSound()
		local enabled = net.ReadBool()
		local str = enabled and "enter" or "exit"
		local sound = "slowmotion/sm_"..str..".wav"
		surface.PlaySound(sound)
	end

	net.Receive("SlowMotionSound", SlowMotionSound)
end




local smduration = CreateConVar("ttt_slowmotion_duration", 1.5, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long should the slowmotion last?")


if SERVER then


	local plymeta = FindMetaTable("Player")
	local SlowMotion_active = false

	local function SlowMotionSound(enabled)
		net.Start("SlowMotionSound")
		net.WriteBool(enabled)
		net.Broadcast()
	end

	function plymeta:EnableSlowMotion()
		if SlowMotion_active then return end
		if self:HasEquipmentItem("ttt_slowmotion") and !self:GetNWBool("SlowMotionUsed", false) then
			self:SetNWBool("SlowMotionUsed", true)
		    game.SetTimeScale(0.3)
			SlowMotion_active = true
			SlowMotionSound(true)
			self:SMReset()
		end
	end

	function plymeta:SMReset()
		local duration = GetConVar("ttt_slowmotion_duration"):GetFloat()
		timer.Create("SMReset" .. self:EntIndex(), duration ,1, function()
				if self:IsValid() and self:GetNWBool("SlowMotionUsed") then
					game.SetTimeScale(1)
					SlowMotion_active = false
					SlowMotionSound(false)
					if self:IsTerror() then
						self:ReloadSM()
					end
				end
			end)
	end
	function plymeta:ReloadSM()
		timer.Create("SMReload" .. self:EntIndex(), 45 ,1, function()
				if self:IsValid() and self:IsTerror() then
					net.Start("SMReload")
					net.Send(self)
					self:SetNWBool("SlowMotionUsed", false)
				end
			end)
	end

	net.Receive("SM_Ask", function(len,ply)
		ply:EnableSlowMotion()
	end)

	hook.Add("TTTPrepareRound", "BeginRoundSM", function()
		for k,v in pairs(player.GetAll()) do
			v:SetNWBool("SlowMotionUsed", false)
			timer.Remove("SMReset" .. v:EntIndex())
			timer.Remove("SMReload" .. v:EntIndex())
		end
	end)

else
	net.Receive("SMReload", function()
		chat.AddText("SlowMotion: ", Color(255,255,255),"Your Slow Motion is ready again!")
		chat.PlaySound()
	end)
end