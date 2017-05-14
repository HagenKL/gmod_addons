if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/icon_doubletap.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_doubletap.png")
  util.AddNetworkString("DrinkingtheDoubleTap")
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
  hook.Add("TTTBoughtItem", "TTTDoubleTap", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_DOUBLETAP)) then
        yCoordinate = getYCoordinate(EQUIP_DOUBLETAP)
      end
    end)
  local material = Material("vgui/ttt/perks/hud_doubletap.png")
  hook.Add("HUDPaint", "TTTDoubleTap", function()
      if LocalPlayer():GetNWBool("DoubleTapActive", false) and LocalPlayer():HasEquipmentItem(EQUIP_DOUBLETAP) then
        surface.SetMaterial(material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(20, yCoordinate, 64, 64)
      end
    end)
    LANG.AddToLanguage("english", "item_doubletap_name", "DoubleTap Root Beer")
    LANG.AddToLanguage("english", "item_doubletap_desc", "DoubleTap Root Beer Perk.\nAutomatically drinks perk to get \na 33% higher fire rate.")
end

EQUIP_DOUBLETAP = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 2048

if SERVER then

  hook.Add("TTTCanOrderEquipment", "TTTDoubleTap", function(ply, id, is_item)
    if tonumber(id) == EQUIP_DOUBLETAP and ply:IsDrinking() then
      return false
    end
  end)
 
  hook.Add("TTTOrderedEquipment", "TTTDoubleTap", function(ply, id, is_item)
      if id == EQUIP_DOUBLETAP then
        ply:Give("ttt_perk_doubletap")
      end
    end)

    hook.Add("TTTPrepareRound", "TTTDoubleTapResettin", function()
      for k,v in pairs(player.GetAll()) do
        timer.Remove("MaketheDoubleTapDrink" .. v:EntIndex())
      end
    end)
end

if CLIENT then
  hook.Add("TTTBodySearchEquipment", "DoubleTapCorpseIcon", function(search, eq)
      search.eq_doubletap = util.BitSet(eq, EQUIP_DOUBLETAP)
    end )

  hook.Add("TTTBodySearchPopulate", "DoubleTapCorpseIcon", function(search, raw)
      if (!raw.eq_doubletap) then
        return end

        local highest = 0
        for _, v in pairs(search) do
          highest = math.max(highest, v.p)
        end

        search.eq_doubletap = {img = "vgui/ttt/icon_doubletap", text = "They drunk a Double Tap Root Beer.", p = highest + 1}
   end )
end
