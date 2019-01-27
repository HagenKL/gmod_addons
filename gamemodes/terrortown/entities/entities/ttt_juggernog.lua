if TTT2 then return end

if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/ic_juggernog.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_juggernog.png")
end

if CLIENT then
  -- feel for to use this function for your own perk, but please credit Zaratusa
  -- your perk needs a "hud = true" in the table, to work properly
  local defaultY = ScrH() / 2 + 20
  local function getYCoordinate(currentPerkID)
    local amount, i, perk = 0, 1
    while (i < currentPerkID) do

      local role = LocalPlayer():GetRole()

      if role == ROLE_INNOCENT then --he gets it in a special way
        if GetEquipmentItem(ROLE_TRAITOR, i) then
          role = ROLE_TRAITOR -- Temp fix what if a perk is just for Detective
        elseif GetEquipmentItem(ROLE_DETECTIVE, i) then
          role = ROLE_DETECTIVE
        end
      end

      perk = GetEquipmentItem(role, i)

      if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
        amount = amount + 1
      end
      i = i * 2
    end

    return defaultY - 80 * amount
  end

  local yCoordinate = defaultY
  -- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
  hook.Add("TTTBoughtItem", "TTTJuggernog", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_JUGGERNOG)) then
        yCoordinate = getYCoordinate(EQUIP_JUGGERNOG)
      end
    end)
  local material = Material("vgui/ttt/perks/hud_juggernog.png")
  hook.Add("HUDPaint", "TTTJuggernog", function()
      if LocalPlayer():GetNWBool("JuggernogActive", false) and LocalPlayer():HasEquipmentItem(EQUIP_JUGGERNOG) then
        surface.SetMaterial(material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(20, yCoordinate, 64, 64)
      end
    end)
    LANG.AddToLanguage("english", "item_juggernog_name", "Juggernog")
    LANG.AddToLanguage("english", "item_juggernog_desc", "Juggernog Perk.\nAutomatically drinks perk to get \nthe maximum health avaible!")
end

EQUIP_JUGGERNOG = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 64

if SERVER then

  hook.Add("TTTCanOrderEquipment", "TTTJuggernog", function(ply, id, is_item)
    if tonumber(id) == EQUIP_JUGGERNOG and ply:IsDrinking() then
      return false
    end
  end)

  hook.Add("TTTOrderedEquipment", "TTTJuggernog", function(ply, id, is_item)
      if id == EQUIP_JUGGERNOG then
        ply:Give("ttt_perk_juggernog")
      end
    end)
end

if CLIENT then
  hook.Add("TTTBodySearchEquipment", "JuggernogCorpseIcon", function(search, eq)
      search.eq_juggernog = util.BitSet(eq, EQUIP_JUGGERNOG)
    end )

  hook.Add("TTTBodySearchPopulate", "JuggernogCorpseIcon", function(search, raw)
      if (!raw.eq_juggernog) then
        return end

        local highest = 0
        for _, v in pairs(search) do
          highest = math.max(highest, v.p)
        end

        search.eq_juggernog = {img = "vgui/ttt/ic_juggernog", text = "They drunk a Juggernog.", p = highest + 1}
   end )
end
