if SERVER then
	AddCSLuaFile()
	resource.AddFile("vgui/ttt/icon_tlh.vmt")
	resource.AddWorkshop("676695745")
	local PLAYER = FindMetaTable("Player")
	util.AddNetworkString( "ColoredMessage" )
	util.AddNetworkString("TLH_Ask")
	util.AddNetworkString("SetTLH")
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
		if ply:HasEquipmentItem(EQUIP_TLH) and ply.TLH and ply:IsTerror() and !ply.TLHInvincible then
			ply:TheLittleHelper()
		elseif ply.TLHInvincible and ply:IsTerror() then
			ply:TLHExhausted()
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

		local width = 200
		local height = 100
		local color = Color(0,200,255,255)
		local function TLHHUD()
			if LocalPlayer().HasTLH and LocalPlayer():IsTerror() then
				local x = ScrW() - width - 25
				local y = ScrH()/2 - height
				draw.RoundedBox( 20, x, y, width , height ,color )
				surface.SetDrawColor(255,255,255,255)
				local time = LocalPlayer():GetNWInt("TLHTime",0)
				local shield = LocalPlayer():GetNWInt("TLHShield",0)
				local w = (time/7)*133
				local w2 = (shield/300)*133
				draw.SimpleText("TLH Seconds: " .. math.Round(time,1), DermaDefault, x + width/2, y + height/7, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				-- draw.SimpleText("Press R to Respawn on your Corpse", DermaDefault, x + width/2, y + height/6, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				-- draw.SimpleText("Press Space to Respawn on Map Spawn", DermaDefault, x + width/2, y + height/3, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				surface.DrawRect(x + width/6, y + height/4, w, 20)
				surface.SetDrawColor(0,0,0,255)
				surface.DrawOutlinedRect(x + width/6, y + height/4, 133, 20)
				draw.SimpleText("TLH Shield: " .. math.Round(shield,1), DermaDefault, x + width/2, y + height/1.8, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				surface.SetDrawColor(255,0,0,255)
				surface.DrawRect(x + width/6, y + height/1.5, w2, 20)
				surface.SetDrawColor(0,0,0,255)
				surface.DrawOutlinedRect(x + width/6, y + height/1.5, 133, 20)
			end
		end

	hook.Add("HUDPaint", "TLHHUD", TLHHUD)

	local function askTLH()
		net.Start("TLH_Ask")
		net.SendToServer()
	end

	concommand.Add("thelittlehelper", askTLH)
end

EQUIP_TLH = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 32

local TheLittleHelper = {
	id = EQUIP_TLH,
	loadout = false,
	type = "item_active",
	material = "vgui/ttt/icon_tlh",
	name = "The Little Helper",
	desc = "With this item you are invincible for 7 seconds. \nBind a key to *thelittlehelper* to use it. \nCAUTION: YOU CAN�T SHOT IN THAT PERIOD OF TIME. \nIt will recharge in 35 seconds.",
	hud = true
}

local detectiveCanUse = CreateConVar("ttt_thelittlehelper_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the The Little Helper.")
local traitorCanUse = CreateConVar("ttt_thelittlehelper_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the The Little Helper.")
local tlhduration = CreateConVar("ttt_thelittlehelper_duration", 7, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long should you be invincible?")

if (detectiveCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], TheLittleHelper)
end
if (traitorCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_TRAITOR], TheLittleHelper)
end

hook.Add("TTTOrderedEquipment", "TTTTLH", function(ply, id, is_item)
		if id == EQUIP_TLH then
			ply.TLH = true
			ply.HasTLH = true
			ply:SetNWInt("TLHTime", 7)
			ply:SetNWInt("TLHShield", 300)
			net.Start("SetTLH")
			net.WriteBool(true)
			net.Send(ply)
		end
	end)

if SERVER then
	function tlhthink()
		for key,ply in pairs(player.GetAll()) do
			if ply.HasTLH then
				if !ply.TLHInvincible and !ply.TLH then
					if ply:GetNWInt("TLHTime") < 7 then
						if CurTime() > ply.tlhtimer then
							ply.tlhtimer = CurTime() + 5
							ply:SetNWInt("TLHTime", ply:GetNWInt("TLHTime") + 1)
						end
					elseif ply:GetNWInt("TLHTime") >= 7 then
						ply:PlayerMsg("Little Helper: ", Color(255,255,255),"Your Little Helper is ready again!")
						ply.TLH = true
						ply:EmitSound("gamefreak/recharged.wav")
						ply:SetNWInt("TLHShield", 300)
					end
				else
					if ply:GetNWInt("TLHTime") > 0 and ply.TLHInvincible then
						if CurTime() > ply.cdtimer then
							ply.cdtimer = CurTime() + 1
							ply:SetNWInt("TLHTime", ply:GetNWInt("TLHTime") - 1)
						end
					elseif ply:GetNWInt("TLHTime") <= 0 and ply.TLHInvincible then
						ply:TLHExhausted()
					end
				end
			end
			if ply.TLHInvincible then
				for k,v in pairs(ply:GetWeapons()) do
					v:SetNextPrimaryFire(CurTime() + 0.2)
					v:SetNextSecondaryFire(CurTime() + 0.2)
				end
			end
		end
	end
	local plymeta = FindMetaTable("Player")
	function plymeta:TheLittleHelper()
		if IsValid(self) then
			self:PlayerMsg("Little Helper: ", Color(255,255,255),"Your Little Helper is now watching over you!")
			self:EmitSound("buttons/blip1.wav")
			self.TLHInvincible = true
			self:Extinguish()
			self.TLH = false
			self.cdtimer = CurTime() + 1
		end
	end
	function plymeta:TLHExhausted()
			if self:IsValid() and self:IsTerror() then
				self:PlayerMsg("Little Helper: ", Color(255,255,255),"Your Little Helper is exhausted!")
				self:EmitSound("gamefreak/reload.wav")
				self.TLHInvincible = false
				self.tlhtimer = CurTime() + 5
				self:SetNWInt("TLHTime", 0)
				self:SetNWInt("TLHShield", 0)
			end
	end
	function TLHOwnerGetsDamage(ent,dmginfo)
		if ent:IsValid() and ent:IsPlayer() and ent.HasTLH and ent.TLHInvincible then
			ent:SetNWInt("TLHShield", ent:GetNWInt("TLHShield",0) - math.Round(dmginfo:GetDamage()))
			if ent:GetNWInt("TLHShield",0) <= 0 then
				ent:TLHExhausted()
			end
			return true
		-- elseif ent:IsPlayer() and math.Round(dmginfo:GetDamage()) >= ent:Health() and ent.TLH then
		-- 	ent:TheLittleHelper()
		-- 	ent:SetHealth(1)
		-- 	return true
		end
	end
	hook.Add("EntityTakeDamage", "TLHSaveLife", TLHOwnerGetsDamage)
	hook.Add( "Think", "TTTTLH", tlhthink)
end

if CLIENT then

	hook.Add("TTTBodySearchEquipment", "TLHCorpseIcon", function(search, eq)
			search.eq_tlh = util.BitSet(eq, EQUIP_TLH)
		end )

	hook.Add("TTTBodySearchPopulate", "TLHCorpseIcon", function(search, raw)
		if (!raw.eq_tlh) then
			return end

			local highest = 0
			for _, v in pairs(search) do
				highest = math.max(highest, v.p)
			end

			search.eq_tlh = {img = "vgui/ttt/icon_tlh", text = "They had a Little Helper watching over them.", p = highest + 1}
	end )
end

local function ResettinTlh()
	for k,v in pairs(player.GetAll()) do
		v.TLH = false
		v.TLHInvincible = false
		v.HasTLH = false
		v.tlhtimer = 0
		v.cdtimer = 0
		v:SetNWInt("TLHTime", 7)
		v:SetNWInt("TLHShield", 300)
	end
end

hook.Add("PlayerDeath", "TLHDeath", function(ply)
	if ply.HasTLH then
		ply.TLH = false
		ply.TLHInvincible = false
		ply.HasTLH = false
		ply.tlhtimer = 0
		ply.cdtimer = 0
		ply:SetNWInt("TLHTime", 7)
		ply:SetNWInt("TLHShield", 300)
		net.Start("SetTLH")
		net.WriteBool(false)
		net.Send(ply)
	end
end )

net.Receive("SetTLH",function()
	LocalPlayer().HasTLH = net.ReadBool()
end)

hook.Add( "TTTPrepareRound", "TLHRESET", ResettinTlh )
