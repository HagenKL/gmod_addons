if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop( "611911370" )
	resource.AddFile("sound/slowmotion/sm_enter.wav")
	resource.AddFile("sound/slowmotion/sm_exit.wav")
	resource.AddFile("materials/VGUI/ttt/slowmotion_icon.vmt")
	resource.AddFile("materials/VGUI/ttt/slowmotion_icon.vtf")
	resource.AddFile("materials/vgui/ttt/perks/hud_slowmo.png")
	util.AddNetworkString("SlowMotionSound")
	util.AddNetworkString("SM_Ask2")
	util.AddNetworkString("SMReload")
end

if CLIENT then
	-- feel for to use this function for your own perk, but please credit Zaratusa
	-- your perk needs a "hud = true" in the table, to work properly
	  local defaultY = ScrH() / 2 + 20
	  local function getYCoordinate(currentPerkID)
	    local amount, i, perk = 0, 1
	    while (i < currentPerkID) do

		local role = LocalPlayer():GetRole()
		if role == ROLE_INNOCENT then
			role = ROLE_TRAITOR -- Temp fix what if a perk is just for Detective
		end
		perk = GetEquipmentItem(role, i)

	      if role == ROLE_INNOCENT then --he gets it in a special way
	        if GetEquipmentItem(ROLE_TRAITOR, i).id then
	          role = ROLE_TRAITOR -- Temp fix what if a perk is just for Detective
	        elseif GetEquipmentItem(ROLE_DETECTIVE, i).id then
	          role = ROLE_DETECTIVE
	        end
	      end

	      perk = GetEquipmentItem(role, i)

	      if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
	        amount = amount + 1
	      end
	      i = i * 2
	    end

	    return defaultY - 80 * amount
	  end

	local yCoordinate = defaultY
	-- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
	hook.Add("TTTBoughtItem", "TTTSM", function()
			if (LocalPlayer():HasEquipmentItem(EQUIP_SM)) then
				yCoordinate = getYCoordinate(EQUIP_SM)
			end
		end)

	local material = Material("vgui/ttt/perks/hud_slowmo.png")
	hook.Add("HUDPaint", "TTTSM", function()
			if (LocalPlayer():HasEquipmentItem(EQUIP_SM)) then
				surface.SetMaterial(material)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(20, yCoordinate, 64, 64)
			end
		end)

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


	LANG.AddToLanguage("english", "item_SlowMotion", "SlowMotion")
	LANG.AddToLanguage("english", "item_SlowMotion_desc", "A Killing Floor like SlowMotion,\nit slows down the game for a short time.\nCooldown is 20 Seconds.\nbind a key for 'SlowMotion' to use it.")

	local function SlowMotionSound()
		local enabled = net.ReadBool()
		local str = enabled and "enter" or "exit"
		local sound = "slowmotion/sm_"..str..".wav"
		surface.PlaySound(sound)
	end

	net.Receive("SlowMotionSound", SlowMotionSound)
end


EQUIP_SM = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 4096

local SlowMotion = {
	avoidTTT2 = true,
	id = EQUIP_SM,
	loadout = false,
	type = "item_active",
	material = "vgui/ttt/slowmotion_icon.vmt",
	name = "item_SlowMotion",
	desc = "item_SlowMotion_desc",
	hud = true
}

table.insert(EquipmentItems[ROLE_TRAITOR], SlowMotion)

if SERVER then

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

	function plymeta:SlowMotion()
		if SlowMotion_active then return end
		if self:HasEquipmentItem(EQUIP_SM) and !self.SlowMotionused then
			self.SlowMotionused = true
		    game.SetTimeScale(0.3)
			SlowMotion_active = true
			SlowMotionSound(true)
			self:SReset()
		end
	end

	function plymeta:SReset()
		local duration = 3
		timer.Create("SMReset" .. self:EntIndex(), duration * timescale ,1, function()
				if self:IsValid() and self.SlowMotionused then
					game.SetTimeScale(1)
					SlowMotion_active = false
					SlowMotionSound(false)
					if self:IsTerror() then
						self:ReloadS()
					end
				end
			end)
	end
	function plymeta:ReloadS()
		timer.Create("SMReload" .. self:EntIndex(), 45 ,1, function()
				if self:IsValid() and self:IsTerror() then
					net.Start("SMReload")
					net.Send(self)
					self.SlowMotionused = false
				end
			end)
	end

	net.Receive("SM_Ask2", function(len,ply)
		ply:SlowMotion()
	end)

	hook.Add("TTTPrepareRound", "BeginRoundSM", function()
		for k,v in pairs(player.GetAll()) do
			v.SlowMotionused = false
			if timer.Exists("SMReset" .. ply:EntIndex()) then
				game.SetTimeScale(1)

				SlowMotion_active = false

				SlowMotionSound(false)

				if ply:IsTerror() then
					ply:ReloadS()
				end

				timer.Remove("SMReset" .. ply:EntIndex())
			end
			timer.Remove("SMReload" .. v:EntIndex())
		end
	end)

else
	hook.Add("TTTBodySearchEquipment", "SMCorpseIcon", function(search, eq)
			search.eq_tlh = util.BitSet(eq, EQUIP_SM)
		end )

	hook.Add("TTTBodySearchPopulate", "SMCorpseIcon", function(search, raw)
		if (!raw.eq_tlh) then
			return end

			local highest = 0
			for _, v in pairs(search) do
				highest = math.max(highest, v.p)
			end

			search.eq_sm = {img = "vgui/ttt/slowmotion_icon", text = "They had a Slowmotion to manipulate the time.", p = highest + 1}
	end )


	net.Receive("SMReload", function()
		chat.AddText("SlowMotion: ", Color(255,255,255),"Your Slow Motion is ready again!")
		chat.PlaySound()
	end)
end
