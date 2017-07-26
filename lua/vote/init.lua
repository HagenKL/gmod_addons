if not TTTGF then
	TTTGF = {}
	file.CreateDir( "vote" )

	AddCSLuaFile("vote/shared/vote_overrides_shd.lua")
	AddCSLuaFile("vote/shared/player.lua")
	AddCSLuaFile("vote/client/cl_halos.lua")
	AddCSLuaFile("vote/client/cl_menu.lua")
	AddCSLuaFile("vote/client/cl_changelog.lua")
	AddCSLuaFile("vote/client/cl_messages.lua")
	AddCSLuaFile("vote/client/cl_deathgrip.lua")
	AddCSLuaFile("vote/cl_init.lua")
	AddCSLuaFile("vote/shared.lua")
	AddCSLuaFile("autorun/ttt_vote_autorun.lua")

	--All Files via Workshop
	resource.AddWorkshop("828347015")
	resource.AddFile("materials/vgui/ttt/icon_hunter.vmt")
	resource.AddFile("materials/vgui/ttt/sprite_hunter.vmt")
	resource.AddFile("materials/vgui/ttt/icon_jackal.vmt")

	--Convars
	CreateConVar("ttt_startvotes","5",{FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Setze die Vote mit der jeder startet.")
	-- local totem = CreateConVar("ttt_totem","1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Soll TTT Totem aktiviert sein?"):GetBool()
	-- local vote = CreateConVar("ttt_vote","1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Soll TTT Vote aktiviert sein?"):GetBool()
	--
	-- SetGlobalBool("ttt_totem", totem)
	-- SetGlobalBool("ttt_vote", vote)
	--
	-- function VoteEnabled() return GetGlobalBool("ttt_vote", false) end
	--
	-- function TotemEnabled() return GetGlobalBool("ttt_totem", false) end

	-- Execute Files
	include("vote/shared/vote_overrides_shd.lua")
	include("vote/shared/player.lua")
	include("vote/server/vote.lua")
	include("vote/server/totem.lua")
	include("vote/server/deathgrip.lua")

	--Tables and vars
	-- if vote then
		TTTGF.votebetters = {}
	-- end
	-- if totem then
		TTTGF.AnyBeacons = true
	-- end

	--NetworkStrings
	-- util.AddNetworkString("SendGlobalBools") --Why cant fucking Global Bools or Replicated CVars work earlier
	-- if vote then
		util.AddNetworkString("VoteChangelog")
		util.AddNetworkString("TTTVoteMenu")
		util.AddNetworkString("TTTPlacedVote")
		util.AddNetworkString("TTTVoteMessage")
		util.AddNetworkString("TTTResetVote")
		util.AddNetworkString("TTTVoteMenu")
		util.AddNetworkString("TTTVoteCurse")
		util.AddNetworkString("TTTVoteFailure")
		util.AddNetworkString("TTTDeathGrip")
		util.AddNetworkString("TTTDeathGripReset")
		util.AddNetworkString("TTTDeathGripMessage")
	-- end

	-- if totem then
		util.AddNetworkString("TTTTotem")
		util.AddNetworkString("TTTVotePlaceTotem")
	-- end

	print("TTT Vote has been successfully loaded!")

	-- hook.Add("PlayerInitialSpawn", "SendGlobalBools", function(ply)
	-- 	net.Start("SendGlobalBools")
	-- 	net.WriteBool(VoteEnabled())
	-- 	net.WriteBool(TotemEnabled())
	-- 	net.Send(ply)
	-- end)
end
