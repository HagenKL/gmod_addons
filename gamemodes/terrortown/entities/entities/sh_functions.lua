if SERVER then
  AddCSLuaFile()
  resource.AddFile("sound/perks/open.wav")
  resource.AddFile("sound/perks/smash.wav")
  resource.AddFile("sound/perks/drink.wav")
  resource.AddFile("sound/perks/burp.wav")
  util.AddNetworkString("ZPBResetMaterials")
end

local Perks = {
  "PHD",
  "StaminUp",
  "Juggernog",
  "Speed",
  "DoubleTap"
}

local plymeta = FindMetaTable("Player")

function plymeta:IsDrinking()
  for _,perk in pairs(Perks) do
    perk = "ttt_perk_" .. string.lower(perk)
    if perk == self:GetActiveWeapon():GetClass() then
      return true
    end
  end
  return false
end

hook.Add("InitPostEntity", "InitPerks", function()
  for _,perk in pairs(Perks) do
    local tbl = {
      id = _G["EQUIP_" .. string.upper(perk)],
      loadout = false,
      type = "item_passive",
      material = "vgui/ttt/ic_" .. string.lower(perk),
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

hook.Add("TTTPrepareRound", "ZPBResetMaterial", function()
  if SERVER then
    net.Start("ZPBResetMaterials")
    net.Broadcast()
  end
end)

hook.Add("PlayerSpawn", "ZPBResetMaterial", function(ply)
  if IsValid(ply) then
    net.Start("ZPBResetMaterials")
    net.Send(ply)
  end
end)

net.Receive("ZPBResetMaterials", function()
  if CLIENT and IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetViewModel()) then
    local vm = LocalPlayer():GetViewModel()
    if oldmat then
      vm:SetMaterial(oldmat)
      oldmat = nil
    else
      vm:SetMaterial("")
    end
  end
end)
