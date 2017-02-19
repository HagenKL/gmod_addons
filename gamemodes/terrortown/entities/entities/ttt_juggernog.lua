if SERVER then
  AddCSLuaFile()
  resource.AddWorkshop("842302491")
  resource.AddFile("materials/vgui/ttt/icon_juggernog.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_juggernog.png")
  util.AddNetworkString("DrinkingtheJuggernog")
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

if SERVER then
  local plymeta = FindMetaTable("Player")
  function plymeta:CanDrinkJugger()
    if IsValid(self) and self:IsTerror() then
      if IsValid(self:GetActiveWeapon()) and self:IsDrinking("ttt_perk_juggernog") then
        timer.Create("MaketheJuggerDrink" .. self:EntIndex(),0.5,0, function()
            if IsValid(self) and IsValid(self:GetActiveWeapon()) and !self:IsDrinking("ttt_perk_juggernog") then
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
