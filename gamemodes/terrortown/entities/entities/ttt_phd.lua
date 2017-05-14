if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/icon_phd.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_phd.png")
  util.AddNetworkString("DrinkingthePHD")
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
  hook.Add("TTTBoughtItem", "TTTPHD", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_PHD)) then
        yCoordinate = getYCoordinate(EQUIP_PHD)
      end
    end)
  local material = Material("vgui/ttt/perks/hud_phd.png")
  hook.Add("HUDPaint", "TTTPHD", function()
      if LocalPlayer():GetNWBool("PHDActive", false) and LocalPlayer():HasEquipmentItem(EQUIP_PHD) then
        surface.SetMaterial(material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(20, yCoordinate, 64, 64)
      end
    end)

    LANG.AddToLanguage("english", "item_phd_name", "PHD Flopper")
    LANG.AddToLanguage("english", "item_phd_desc", "PHD Flopper Perk.\nAutomatically drinks perk to become \nimmune to fall damage,\nexplosion damage, and create an explosion\nwhere you land.")
end

EQUIP_PHD = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 128

if SERVER then

  hook.Add("TTTCanOrderEquipment", "TTTPHD", function(ply, id, is_item)
    if tonumber(id) == EQUIP_PHD and ply:IsDrinking() then
      return false
    end
  end)

  hook.Add("TTTOrderedEquipment", "TTTPHD", function(ply, id, is_item)
      if id == EQUIP_PHD then
        ply:Give("ttt_perk_phd")
      end
    end)
    hook.Add("TTTPrepareRound", "TTTPHDResettin", function()
      for k,v in pairs(player.GetAll()) do
        timer.Remove("MakethePHDDrink" .. v:EntIndex())
      end
    end)
end

if CLIENT then
  hook.Add("TTTBodySearchEquipment", "PHDCorpseIcon", function(search, eq)
      search.eq_phd = util.BitSet(eq, EQUIP_PHD)
    end )

  hook.Add("TTTBodySearchPopulate", "PHDCorpseIcon", function(search, raw)
      if (!raw.eq_phd) then
        return end

        local highest = 0
        for _, v in pairs(search) do
          highest = math.max(highest, v.p)
        end

        search.eq_phd = {img = "vgui/ttt/icon_phd", text = "They drunk a PHD Flopper.", p = highest + 1}
      end )
  end
