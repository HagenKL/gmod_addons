if true then return end

if SERVER then
	AddCSLuaFile()
	resource.AddFile("vgui/ttt/icon_tlh.vmt")
	resource.AddWorkshop("676695745")

	util.AddNetworkString( "ColoredMessage" )
	util.AddNetworkString("TLH_Ask")
	util.AddNetworkString("SetTLH")

  local PLAYER = FindMetaTable("Player")

	function PLAYER:PlayerMsg(...)
		local args = {...}
		net.Start("ColoredMessage")
		net.WriteTable(args)
		net.Send(self)
	end

	net.Receive("TLH_Ask", function(len,ply)
		if ply:HasEquipmentItem("item_ttt_thelittlehelper") and ply.TLH and ply:IsTerror() and !ply.TLHInvincible then
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

ITEM.hud  = "vgui/ttt/perks/hud_tlh.png"
ITEM.EquipMenuData = {
  type = "item_active",
  name = "The Little Helper",
  desc = "With this item you are invincible for 7 seconds. \nBind a key to *thelittlehelper* to use it. \nCAUTION: YOU CAN�T SHOT IN THAT PERIOD OF TIME. \nIt will recharge in 35 seconds.",
}

ITEM.corpseDesc = "They had a Little Helper watching over them."
ITEM.credits = 1
ITEM.material = "vgui/ttt/icon_tlh"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

local tlhduration = CreateConVar("ttt_thelittlehelper_duration", 7, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long should you be invincible?")

function ITEM:Bought(ply)
		ply.TLH = true
		ply.HasTLH = true

		ply:SetNWInt("TLHTime", 7)
		ply:SetNWInt("TLHShield", 300)

		net.Start("SetTLH")
		net.WriteBool(true)
		net.Send(ply)
end

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
