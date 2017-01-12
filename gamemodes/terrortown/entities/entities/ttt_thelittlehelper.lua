if SERVER then
	AddCSLuaFile()
	resource.AddFile("vgui/ttt/icon_tlh.vmt")
	resource.AddWorkshop("676695745")
	local PLAYER = FindMetaTable("Player")
	util.AddNetworkString( "ColoredMessage" )
	util.AddNetworkString("TLH_Ask")
	util.AddNetworkString("TLHStart")
	util.AddNetworkString("TLHReload")
	util.AddNetworkString("TLHReloaded")
	function BroadcastMsg(...)
		local args = {...}
		net.Start("ColoredMessage")
		net.WriteTable(args)
		net.Broadcast()
	end

	function PLAYER:PlayerMsg(...)
		local args = {...}
		net.Start("ColoredMessage")
		net.WriteTable(args)
		net.Send(self)
	end
	net.Receive("TLH_Ask", function(len,ply)
			if ply.TLH == true and ply:Alive() and ply:IsTerror() then
				ply:TheLittleHelper()
			end
		end )
end

if CLIENT then
	net.Receive("ColoredMessage",function(len)
			local msg = net.ReadTable()
			chat.AddText(unpack(msg))
			chat.PlaySound()
		end)
	-- feel for to use this function for your own perk, but please credit Zaratusa
	-- your perk needs a "hud = true" in the table, to work properly
	local defaultY = ScrH() / 2 + 20
	local function getYCoordinate(currentPerkID)
		local amount, i, perk = 0, 1
		while (i < currentPerkID) do
			perk = GetEquipmentItem(LocalPlayer():GetRole(), i)
			if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
				amount = amount + 1
			end
			i = i * 2
		end

		return defaultY - 80 * amount
	end

	local yCoordinate = defaultY
	-- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
	hook.Add("TTTBoughtItem", "TTTTLH2", function()
			if (LocalPlayer():HasEquipmentItem(EQUIP_TLH)) then
				yCoordinate = getYCoordinate(EQUIP_TLH)
			end
		end)

	local material = Material("vgui/ttt/perks/hud_tlh.png")
	hook.Add("HUDPaint", "TTTTLH", function()
			if (LocalPlayer():HasEquipmentItem(EQUIP_TLH)) then
				surface.SetMaterial(material)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(20, yCoordinate, 64, 64)
			end
		end)

	local function askTLH()
		net.Start("TLH_Ask")
		net.SendToServer()
	end

	concommand.Add("thelittlehelper", askTLH)
end

local function getNextFreeID()
	local freeID, i = 1, 1
	while (freeID == 1) do
		if (!istable(GetEquipmentItem(ROLE_DETECTIVE, i))
			and !istable(GetEquipmentItem(ROLE_TRAITOR, i))) then
			freeID = i
		end
		i = i * 2
	end

	return freeID
end

EQUIP_TLH = getNextFreeID()

local TheLittleHelper = {
	id = EQUIP_TLH,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_tlh",
	name = "The Little Helper",
	desc = "With this Item you get invincible for 7 seconds. \nBind a key to *thelittlehelper* to use it. \nCAUTION: YOU CAN�T SHOT IN THAT PERIOD OF TIME. \nIt will recharge in 20 seconds.",
	hud = true
}

local detectiveCanUse = CreateConVar("ttt_thelittlehelper_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the The Little Helper.")
local traitorCanUse = CreateConVar("ttt_thelittlehelper_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the The Little Helper.")
local tlhduration = CreateConVar("ttt_thelittlehelper_duration", 7, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long the invincibility should be?")

if (detectiveCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], TheLittleHelper)
end
if (traitorCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_TRAITOR], TheLittleHelper)
end

hook.Add("TTTOrderedEquipment", "TTTTLH", function(ply, equipment, is_item)
		if is_item == EQUIP_TLH then
			ply.TLH = true
		end
	end)

if SERVER then
	function tlhthink()
		for key,ply in pairs(player.GetAll()) do
			if ply.TLHInvincible then
				for _, v in pairs(ply:GetWeapons()) do
					v:SetNextPrimaryFire(CurTime() + 0.2)
					v:SetNextSecondaryFire(CurTime() +0.2)
				end
			end
		end
	end
	local plymeta = FindMetaTable("Player")
	function plymeta:TheLittleHelper()
		if IsValid(self) then
			self:PlayerMsg("Little Helper: ", Color(255,255,255),"Your Little Helper was activated!")
			net.Start("TLHStart")
			net.Send(self)
			self.TLHInvincible = true
			self:Extinguish()
			self.TLH = false
			self:TLHReset()
		end
	end
	function plymeta:TLHReset()
		timer.Create("TLHReset" .. self:EntIndex(), tlhduration:GetInt() ,1, function()
				if self:IsValid() and self.TLHInvincible == true and self:IsTerror() then
					self.TLH = false
					self:PlayerMsg("Little Helper: ", Color(255,255,255),"Your Little Helper is exhausted!")
					net.Start("TLHReload")
					net.Send(self)
					self:SetNWBool("CanAttack", true)
					self.TLHInvincible = false
					self:ReloadTLH()
				end
			end)
	end
	function plymeta:ReloadTLH()
		timer.Create("TLHReload" .. self:EntIndex(), 30 ,1, function()
				if self:IsValid() and self:IsTerror() then
					self:PlayerMsg("Little Helper: ", Color(255,255,255),"Your Little Helper is ready again!")
					net.Start("TLHReloaded")
					net.Send(self)
					self.TLH = true
				end
			end)
	end
	function TLHOwnerGetsDamage(ent,dmginfo)
		if ent:IsValid() and ent:IsPlayer() and ent:HasEquipmentItem(EQUIP_TLH) and ent.TLHInvincible == true then
			return true
		/*elseif ent:IsPlayer() and math.Round(dmginfo:GetDamage()) >= ent:Health() and ent.TLH then
			ent:TheLittleHelper()
			ent:SetHealth(1)
			return true*/
		end
	end
	hook.Add("EntityTakeDamage", "TLHSaveLife", TLHOwnerGetsDamage)
end
hook.Add( "Think", "TTTTLH", tlhthink)

if CLIENT then
	net.Receive("TLHStart", function()
			surface.PlaySound("buttons/blip1.wav")
		end)
	net.Receive("TLHReload", function()
			surface.PlaySound("gamefreak/reload.wav")
		end)
	net.Receive("TLHReloaded", function()
			surface.PlaySound("gamefreak/recharged.wav")
		end)
end

local function ResettinTlh()
	for k,v in pairs(player.GetAll()) do
		v.TLH = false
		v.TLHInvincible = false
		timer.Remove("TLHReset" .. v:EntIndex())
		timer.Remove("TLHReload" .. v:EntIndex())

	end
end

hook.Add("PlayerDeath", "TLHDeath", function(ply)
		ply.TLH = false
		ply.TLHInvincible = false
	end )

hook.Add( "TTTPrepareRound", "TLHRESET", ResettinTlh )
