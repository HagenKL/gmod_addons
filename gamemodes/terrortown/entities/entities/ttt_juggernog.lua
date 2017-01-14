if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("842302491")
	resource.AddFile("materials/vgui/ttt/icon_juggernog.vmt")
	util.AddNetworkString("DrinkingtheJuggernog")
end

function getNextFreeID()
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

EQUIP_JUGGERNOG = getNextFreeID()

local Juggernog = {
	id = EQUIP_JUGGERNOG,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_juggernog",
	name = "Juggernog",
	desc = "Get the maximum health avaible with this drink!",
	hud = false
}

local detectiveCanUse = CreateConVar("ttt_juggernog_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the Juggernog.")
local traitorCanUse = CreateConVar("ttt_juggernog_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the Juggernog.")

if (detectiveCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], Juggernog)
end
if (traitorCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_TRAITOR], Juggernog)
end

if SERVER then
	local function DoDrinkJugger(ply)
		if IsValid(ply) and ply:IsTerror() then
			if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "ttt_perk_staminup" or ply:GetActiveWeapon():GetClass() == "ttt_perk_phd" then
				timer.Simple(0.5, function() if IsValid(ply) then DoDrinkJugger(ply) end end)
			else
				ply:Give("ttt_perk_juggernog")
				ply:SelectWeapon("ttt_perk_juggernog")
				ply:GetWeapon("ttt_perk_juggernog"):DrinkTheBottle()
			end
		end
	end

	hook.Add("TTTOrderedEquipment", "TTTJuggernog", function(ply, equipment, is_item)
			if is_item == EQUIP_JUGGERNOG then
				DoDrinkJugger(ply)
			end
		end)
end
