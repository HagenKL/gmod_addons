if SERVER then
  AddCSLuaFile()
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
    LANG.AddToLanguage("english", "item_staminup_name", "Stamin-Up")
    LANG.AddToLanguage("english", "item_staminup_desc", "Stamin-Up Perk.\nAutomatically drinks perk to greatly increase\nwalk speed!")
end

local function getNextFreeID()
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

EQUIP_STAMINUP = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 256

if SERVER then

  hook.Add("TTTCanOrderEquipment", "TTTStaminup", function(ply, id, is_item)
    if tonumber(id) == EQUIP_STAMINUP and ply:IsDrinking() then
      return false
    end
  end)

  hook.Add("TTTOrderedEquipment", "TTTStaminup", function(ply, id, is_item)
      if id == EQUIP_STAMINUP then
        ply:Give("ttt_perk_staminup")
      end
    end)
    hook.Add("TTTPrepareRound", "TTTStaminupResettin", function()
      for k,v in pairs(player.GetAll()) do
        timer.Remove("MaketheStaminUpDrink" .. v:EntIndex())
      end
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