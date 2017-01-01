-- Copyright 2014 - Code-of-Craft.de --
AddCSLuaFile("autorun/client/cl_SlowMotion.lua")
AddCSLuaFile("autorun/sh_SlowMotion.lua")

resource.AddFile("sound/sm_enter.wav")
resource.AddFile("sound/sm_exit.wav")
resource.AddFile("materials/VGUI/ttt/slowmotion_icon.vmt")
resource.AddFile("materials/VGUI/ttt/slowmotion_icon.vtf")

util.AddNetworkString("SlowMotion")
util.AddNetworkString("SlowMotion_Ask")
util.AddNetworkString("SendSMInfos")

CreateConVar("ttt_SlowMotion_enable", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar("ttt_SlowMotion_endround", "0") -- slow motion effect when a round ends
CreateConVar("ttt_SlowMotion_duration", "1.5")
CreateConVar("ttt_SlowMotion_detective", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar("ttt_SlowMotion_detective_loadout", "0")
CreateConVar("ttt_SlowMotion_traitor", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar("ttt_SlowMotion_traitor_loadout", "0")

local SlowMotion_active = false
		
local function bool_to_bit(bool)
	return bool and 1 or 0
end
	
-- FCVAR_REPLICATED is broke on gmod, so..
hook.Add("PlayerAuthed", "PlayerAuthedSM", function(ply)
	net.Start("SendSMInfos")
	net.WriteUInt(bool_to_bit(GetConVar("ttt_SlowMotion_enable"):GetBool()), 1)
	net.WriteUInt(bool_to_bit(GetConVar("ttt_SlowMotion_traitor"):GetBool()), 1)
	net.WriteUInt(bool_to_bit(GetConVar("ttt_SlowMotion_detective"):GetBool()), 1)
	net.Send(ply)
end)

hook.Add("PlayerInitialSpawn", "PlayerInitialSpawnSM", function(ply)
	ply:SetUsedSlowMotion(false)
end)
		
local meta = FindMetaTable("Player")
function meta:SetUsedSlowMotion(b)
	self:SetNWBool("SlowMotion", b)
end
meta = nil	
	
local function informZed(bit, ply)
	hook.Call("SlowMotion", GAMEMODE, ply, bit)
	net.Start("SlowMotion")
	net.WriteUInt(bit and 1 or 0, 1)
	if IsValid(ply) then
		net.WriteUInt(1,1)
		net.WriteEntity(ply)
	else
		net.WriteUInt(0,1)
	end
	net.Broadcast()
end
		
hook.Add("TTTBeginRound", "BeginRoundSM", function()
	for k,v in pairs(player.GetAll()) do
		if v:UsedSlowMotion() then
		    v:SetUsedSlowMotion(false)
		end
	end
end)
	
hook.Add("TTTEndRound", "EndRoundSM", function()
	if GetConVar("ttt_SlowMotion_endround"):GetBool() then 
	    GAMEMODE:EnableSlowMotion()
    end
end)
	
-- Also using Initialize, so this works with hooks
hook.Add("Initialize", "InitializeSMHooks", function()
	
	-- Called when the player tries to use a zed time, return false to prevent
	function GAMEMODE:CanUseSlowMotion(ply)
		if not IsValid(ply) then return false end
		if SlowMotion_active then return false end
		if ply:IsActiveSpecial() then
			local found = false
			for k,v in pairs(EquipmentItems[ply:GetRole()]) do
				if v.id == EQUIP_SlowMotion then
					found = true
				end
			end
			if not found then
				LANG.Msg(ply, "item_SlowMotion_role")
				return false
			end
			if ply:HasEquipmentItem(EQUIP_SlowMotion) then
			    if ply:UsedSlowMotion() then
					LANG.Msg(ply, "item_SlowMotion_once")
					return false
				end
				return true
			else
				LANG.Msg(ply, "item_SlowMotion_nobuy")
				return false
			end
		end
		return false
	end  
		
	-- Called to enable SlowMotion
	function GAMEMODE:EnableSlowMotion(ply)
	    if IsValid(ply) then ply:SetUsedSlowMotion(true) end
	    game.SetTimeScale(0.3)
		informZed(true, ply)
		SlowMotion_active = true
		local duration = GetConVar("ttt_SlowMotion_duration"):GetFloat()
		timer.Simple(duration, function()
		    game.SetTimeScale(1)
			informZed(false)
			SlowMotion_active = false
		end)
	end
		
	-- Called when SlowMotion is enabled or disabled
	function GAMEMODE:SlowMotion(ply, enabled)
		if enabled and IsValid(ply) then
			DamageLog(string.format("SlowMotion:\t %s [%s] used his SlowMotion", ply:Nick(), ply:GetRoleString()))
		end
	end
end)
	
net.Receive("SlowMotion_Ask", function(len,ply)
	if hook.Call("CanUseSlowMotion", GAMEMODE, ply) then
		hook.Call("EnableSlowMotion", GAMEMODE, ply)
	end
end)