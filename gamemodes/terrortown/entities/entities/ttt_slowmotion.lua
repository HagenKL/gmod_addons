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

if CLIENT then
	-- feel for to use this function for your own perk, but please credit Zaratusa
	-- your perk needs a "hud = true" in the table, to work properly
	local defaultY = ScrH() / 2 + 20
	local function getYCoordinate(currentPerkID)
		local amount, i, perk = 0, 1
		while (i < currentPerkID) do
			local role = LocalPlayer():GetRole()
			if role == ROLE_INNOCENT then
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
		net.Start("SM_Ask")
		net.SendToServer()
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

local detectiveCanUse = CreateConVar("ttt_slowmotion_det", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the SlowMotion .")
local traitorCanUse = CreateConVar("ttt_slowmotion_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the SlowMotion.")
local smduration = CreateConVar("ttt_slowmotion_duration", 1.5, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long should the slowmotion last?")

if (detectiveCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], SlowMotion)
end
if (traitorCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_TRAITOR], SlowMotion)
end

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
		if self:HasEquipmentItem(EQUIP_SM) and !self:GetNWBool("SlowMotionUsed", false) then
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
		timer.Create("SMReload" .. self:EntIndex(), 20 ,1, function()
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
