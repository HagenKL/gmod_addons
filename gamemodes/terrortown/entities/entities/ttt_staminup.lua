if SERVER then
  AddCSLuaFile()
  resource.AddWorkshop("")
  resource.AddFile("materials/vgui/ttt/icon_staminup.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_staminup.png")
  util.AddNetworkString("DrinkingtheStaminup")
end

if CLIENT then
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
  hook.Add("TTTBoughtItem", "TTTStaminup", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_STAMINUP)) then
        yCoordinate = getYCoordinate(EQUIP_STAMINUP)
      end
    end)
  local material = Material("vgui/ttt/perks/hud_staminup.png")
  hook.Add("HUDPaint", "TTTStaminup", function()
      if LocalPlayer():GetNWBool("StaminUpActive", false) and LocalPlayer():HasEquipmentItem(EQUIP_STAMINUP) then
        surface.SetMaterial(material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(20, yCoordinate, 64, 64)
      end
    end)

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

EQUIP_STAMINUP = getNextFreeID()

local STAMINUP = {
  id = EQUIP_STAMINUP,
  loadout = false,
  type = "item_passive",
  material = "vgui/ttt/icon_staminup",
  name = "Stamin-Up Perk",
  desc = "Stamin-Up Perk.\nAutomatically drink perk to greatly increase\nwalk speed.",
  hud = true
}

local detectiveCanUse = CreateConVar("ttt_staminup_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the Stamin-Up.")
local traitorCanUse = CreateConVar("ttt_staminup_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the Stamin-Up.")

if (detectiveCanUse:GetBool()) then
  table.insert(EquipmentItems[ROLE_DETECTIVE], STAMINUP)
end
if (traitorCanUse:GetBool()) then
  table.insert(EquipmentItems[ROLE_TRAITOR], STAMINUP)
end

if SERVER then

  local plymeta = FindMetaTable("Player")
  function plymeta:CanDrinkStaminup()
    if IsValid(self) and self:IsTerror() then
      if IsValid(self:GetActiveWeapon()) and (self:GetActiveWeapon():GetClass() == "ttt_perk_juggernog" or self:GetActiveWeapon():GetClass() == "ttt_perk_phd") then
        timer.Create("MaketheStaminUpDrink",0.5,0, function()
            if IsValid(self) and IsValid(self:GetActiveWeapon()) and (self:GetActiveWeapon():GetClass() != "ttt_perk_juggernog" and self:GetActiveWeapon():GetClass() != "ttt_perk_phd") then
              self:GivetheStaminup()
              timer.Remove("MaketheStaminUpDrink")
            end
          end)
      else
        self:GivetheStaminup()
      end
    end
  end

  function plymeta:GivetheStaminup()
    self:Give("ttt_perk_staminup")
    self:SelectWeapon("ttt_perk_staminup")
    if self:HasWeapon("ttt_perk_staminup") then
      self:GetWeapon("ttt_perk_staminup"):DrinkTheBottle()
    elseif IsValid(self) and !self:HasWeapon("ttt_perk_staminup") then
      print("hi3")
      self:CanDrinkStaminup()
    end
  end

  hook.Add("TTTOrderedEquipment", "TTTStaminup", function(ply, equipment, is_item)
      if is_item == EQUIP_STAMINUP then
        ply:CanDrinkStaminup()
      end
    end)
    hook.Add("TTTPrepareRound", "TTTStaminupResettin", function()
      timer.Remove("MaketheStaminUpDrink")
    end)
end

if CLIENT then
  hook.Add("TTTBodySearchEquipment", "StaminupCorpseIcon", function(search, eq)
      search.eq_staminup = util.BitSet(eq, EQUIP_STAMINUP)
    end )

  hook.Add("TTTBodySearchPopulate", "StaminupCorpseIcon", function(search, raw)
      if (!raw.eq_staminup) then
        return end

        local highest = 0
        for _, v in pairs(search) do
          highest = math.max(highest, v.p)
        end

        search.eq_staminup = {img = "vgui/ttt/icon_staminup", text = "They drunk a Stamin-Up.", p = highest + 1}
      end )
  end
