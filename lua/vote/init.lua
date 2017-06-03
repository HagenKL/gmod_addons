if not TTTVote then
	TTTVote = {}
	file.CreateDir( "vote" )

	AddCSLuaFile("vote/shared/vote_overrides_shd.lua")
	AddCSLuaFile("vote/shared/player.lua")
	AddCSLuaFile("vote/client/cl_halos.lua")
	AddCSLuaFile("vote/client/cl_menu.lua")
	AddCSLuaFile("vote/client/cl_changelog.lua")
	AddCSLuaFile("vote/client/cl_messages.lua")
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

	-- Execute Files
	include("vote/shared/vote_overrides_shd.lua")
	include("vote/shared/player.lua")
	include("vote/server/vote.lua")
	include("vote/server/totem.lua")

	--Tables
	TTTVote.votebetters = {}
	TTTVote.AnyBeacons = true

	--NetworkStrings
	util.AddNetworkString("VoteChangelog")
	util.AddNetworkString("TTTVoteMenu")
	util.AddNetworkString("TTTPlacedVote")
	util.AddNetworkString("TTTVoteMessage")
	util.AddNetworkString("TTTResetVote")
	util.AddNetworkString("TTTTotem")
	util.AddNetworkString("TTTVotePlaceTotem")
	util.AddNetworkString("TTTVoteMenu")
	util.AddNetworkString("TTTVoteCurse")
	util.AddNetworkString("TTTVoteFailure")

	print("TTT Vote has been successfully loaded!")
end
