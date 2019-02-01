if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("611911370")

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
	desc = "item_SlowMotion_desc"
}
ITEM.material = "vgui/ttt/slowmotion_icon.vmt"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

if CLIENT then
	local function askSM()
		if not TTT2 then
			net.Start("SM_Ask2")
			net.SendToServer()
		else
			net.Start("SM_Ask")
			net.SendToServer()
		end
	end
	concommand.Add("SlowMotion", askSM)

	LANG.AddToLanguage("English", "item_SlowMotion", "SlowMotion")
	LANG.AddToLanguage("English", "item_SlowMotion_desc", "A Killing Floor like SlowMotion,\nit slows down the game for a short time.\nCooldown is 45 Seconds.\nbind a key for 'SlowMotion' to use it.")

	local function SlowMotionSound()
		local enabled = net.ReadBool()

		surface.PlaySound("slowmotion/sm_" .. (enabled and "enter" or "exit") .. ".wav")
	end
	net.Receive("SlowMotionSound", SlowMotionSound)

	net.Receive("SMReload", function()
		chat.AddText("SlowMotion: ", Color(255, 255, 255), "Your Slow Motion is ready again!")
		chat.PlaySound()
	end)
else
	local timescale = 0.3
	local cooldown = 45
	local duration = 5

	local plymeta = FindMetaTable("Player")
	local SlowMotion_active = false

	local function SlowMotionSound(enabled)
		net.Start("SlowMotionSound")
		net.WriteBool(enabled)
		net.Broadcast()
	end

	function plymeta:EnableSlowMotion2()
		if SlowMotion_active then return end

		if self:HasEquipmentItem("item_ttt_slowmotion") and not self.SlowMotionused then
			self.SlowMotionused = true

			game.SetTimeScale(timescale)

			SlowMotion_active = true

			SlowMotionSound(true)

			self:SMReset2()
		end
	end

	function plymeta:SMReset2()
		local slf = self

		timer.Create("SMReset" .. self:EntIndex(), duration * timescale, 1, function()
			if IsValid(slf) and slf.SlowMotionused then
				game.SetTimeScale(1)

				SlowMotion_active = false

				SlowMotionSound(false)

				if slf:IsActive() then
					slf:ReloadSM2()
				end
			end
		end)
	end

	function plymeta:ReloadSM2()
		local slf = self

		timer.Create("SMReload" .. self:EntIndex(), cooldown, 1, function()
			if IsValid(slf) and slf:IsTerror() then
				net.Start("SMReload")
				net.Send(slf)

				slf.SlowMotionused = false
			end
		end)
	end

	net.Receive("SM_Ask", function(len, ply)
		ply:EnableSlowMotion2()
	end)

	local function ResetSlowMotion(ply)
		ply.SlowMotionused = false

		if timer.Exists("SMReset" .. ply:EntIndex()) then
			game.SetTimeScale(1)

			SlowMotion_active = false

			SlowMotionSound(false)

			if ply:IsTerror() then
				ply:ReloadSM2()
			end

			timer.Remove("SMReset" .. ply:EntIndex())
		end

		timer.Remove("SMReload" .. ply:EntIndex())
	end

	function ITEM:Reset(ply)
		ResetSlowMotion(ply)
	end
end
