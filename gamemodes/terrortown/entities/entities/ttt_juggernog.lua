if SERVER then
  AddCSLuaFile()
  resource.AddWorkshop("842302491")
  resource.AddFile("materials/vgui/ttt/icon_juggernog.vmt")
  util.AddNetworkString("DrinkingtheJuggernog")
end

function getNextFreeID()
  local freeID, i = 1, 1
  while (freeID == 1) do
    if (!GetEquipmentItem(ROLE_DETECTIVE, i)
      and !GetEquipmentItem(ROLE_TRAITOR, i)) then
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
  local plymeta = FindMetaTable("Player")
  function plymeta:CanDrinkJugger()
    if IsValid(self) and self:IsTerror() then
      if IsValid(self:GetActiveWeapon()) and (self:GetActiveWeapon():GetClass() == "ttt_perk_staminup" or self:GetActiveWeapon():GetClass() == "ttt_perk_phd") then
        timer.Create("MaketheJuggerDrink" .. self:EntIndex(),0.5,0, function()
            if IsValid(self) and IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon():GetClass() != "ttt_perk_staminup" and self:GetActiveWeapon():GetClass() != "ttt_perk_phd" then
              self:GivetheJugger()
              timer.Remove("MaketheJuggerDrink" .. self:EntIndex())
            end
          end)
      else
        self:GivetheJugger()
      end
    end
  end

  function plymeta:GivetheJugger()
    self:Give("ttt_perk_juggernog")
    self:SelectWeapon("ttt_perk_juggernog")
    if self:HasWeapon("ttt_perk_juggernog") then
      self:GetWeapon("ttt_perk_juggernog"):DrinkTheBottle()
    elseif IsValid(self) and !self:HasWeapon("ttt_perk_juggernog") then
      self:CanDrinkJugger()
    end
  end

  hook.Add("TTTOrderedEquipment", "TTTJuggernog", function(ply, equipment, is_item)
      if is_item == EQUIP_JUGGERNOG then
        ply:CanDrinkJugger()
      end
    end)
    hook.Add("TTTPrepareRound", "TTTJuggernogResettin", function()
      for k,v in pairs(player.GetAll()) do
        timer.Remove("MaketheJuggerDrink" .. v:EntIndex())
      end
    end)
end
