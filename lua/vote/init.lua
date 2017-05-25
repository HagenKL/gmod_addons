if not TTTVote then
	TTTVote = {}
	file.CreateDir( "vote" )

	AddCSLuaFile("vote/shared/vote_overrides_shd.lua")
	AddCSLuaFile("vote/shared/halos_shd.lua")
	AddCSLuaFile("vote/shared/player.lua")
	AddCSLuaFile("vote/client/cl_menu.lua")
	AddCSLuaFile("vote/client/cl_messages.lua")
	AddCSLuaFile("vote/cl_init.lua")
	AddCSLuaFile("vote/shared.lua")
	AddCSLuaFile("autorun/ttt_vote_autorun.lua")

	--All Files via Workshop
	resource.AddWorkshop("828347015")
	resource.AddFile("materials/vgui/ttt/icon_hunter.vmt")
	resource.AddFile("materials/vgui/ttt/sprite_hunter.vmt")
	resource.AddFile("materials/vgui/ttt/icon_survivor.vmt")

	--Convars
	CreateConVar("ttt_startvotes","5",{FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Setze die Vote mit der jeder startet.")
	--local totem = CreateConVar("ttt_totem", "1",{FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Soll TTT Totem an sein?")

	-- Bool for Client
	--SetGlobalBool("ttt_totem", totem:GetBool())

	-- Execute Files
	include("vote/shared/vote_overrides_shd.lua")
	include("vote/shared/halos_shd.lua")
	include("vote/shared/player.lua")
	include("vote/server/vote.lua")
	include("vote/server/totem.lua")

	--Tables
	TTTVote.votebetters = TTTVote.votebetters or {}
	--if totem then
	TTTVote.AnyBeacons = true
	--end

	--NetworkStrings
	util.AddNetworkString("TTTVoteMenu")
	util.AddNetworkString("TTTPlacedVote")
	util.AddNetworkString("TTTVoteMessage")
	util.AddNetworkString("TTTResetVote")
	util.AddNetworkString("TTTVoteAddHalos")
	util.AddNetworkString("TTTVoteRemoveHalos")
	util.AddNetworkString("TTTTotem")
	util.AddNetworkString("TTTVoteRemoveAllHalos")
	util.AddNetworkString("TTTVotePlaceTotem")
	util.AddNetworkString("TTTVoteMenu")
	util.AddNetworkString("TTTVoteCurse")
	util.AddNetworkString("TTTVoteFailure")

	print("TTT Vote has been successfully loaded!")
end
