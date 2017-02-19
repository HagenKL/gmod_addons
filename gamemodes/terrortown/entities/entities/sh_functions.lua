if SERVER then
  AddCSLuaFile()
  resource.AddFile("sound/perks/open.wav")
  resource.AddFile("sound/perks/smash.wav")
  resource.AddFile("sound/perks/drink.wav")
  resource.AddFile("sound/perks/burp.wav")
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

local Perks = {
  "PHD",
  "StaminUp",
  "Juggernog",
  "Speed"
}

local plymeta = FindMetaTable("Player")

function plymeta:IsDrinking(activeperk)
  for _,perk in pairs(Perks) do
    perk = "ttt_perk_" .. string.lower(perk)
    if perk != self:GetActiveWeapon():GetClass() then
      continue
    else
      if perk != activeperk then
        return true
      else
        return false
      end
    end
  end
  return false
end

hook.Add("Initialize", "InitPerks", function()
  local count = 1
  for _,perk in pairs(Perks) do
    count = count*2
    _G["EQUIP_" .. string.upper(perk)] = getNextFreeID()*count
  end
end)

hook.Add("InitPostEntity", "InitPerks", function()
  for _,perk in pairs(Perks) do
    local tbl = {
      id = _G["EQUIP_" .. string.upper(perk)],
      loadout = false,
      type = "item_passive",
      material = "vgui/ttt/icon_" .. string.lower(perk),
      name = "item_" .. string.lower(perk) .. "_name",
      desc = "item_" .. string.lower(perk) .. "_desc",
      hud = true
    }
    local detectiveCanUse = CreateConVar("ttt_" .. string.lower(perk) .. "_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the" .. perk .. ".")
    local traitorCanUse = CreateConVar("ttt_" .. string.lower(perk) .. "_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the " .. perk .. ".")
    if (detectiveCanUse:GetBool()) then
      table.insert(EquipmentItems[ROLE_DETECTIVE], tbl)
    end
    if (traitorCanUse:GetBool()) then
      table.insert(EquipmentItems[ROLE_TRAITOR], tbl)
    end
  end
end)

hook.Add("TTTPrepareRound", "ResetMaterial", function()
  if CLIENT and oldmat != nil then
    local vm = LocalPlayer():GetViewModel()
    vm:SetMaterial(oldmat)
    oldmat = nil
  end
end)
