if SERVER then -- Currently Disabled due to balance reason, uncomment so enable, also uncomment in sh_functions.lua line 27
  -- AddCSLuaFile()
  -- resource.AddFile("materials/vgui/ttt/icon_doubletap.vmt")
  -- resource.AddFile("materials/vgui/ttt/perks/hud_doubletap.png")
  -- util.AddNetworkString("DrinkingtheDoubleTap")
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
    LANG.AddToLanguage("english", "item_doubletap_desc", "Double Tap Root Beer Perk.\nAutomatically drinks perk to get \n33% higher firerate, 33% higher recoil,\ntwice the spread and twice the amount of bullets.")
end

if SERVER then

  local plymeta = FindMetaTable("Player")
  function plymeta:CanDrinkDoubleTap()
    if IsValid(self) and self:IsTerror() then
      if IsValid(self:GetActiveWeapon()) and self:IsDrinking("ttt_perk_doubletap") then
        timer.Create("MaketheDoubleTapDrink" .. self:EntIndex(),0.5,0, function()
            if IsValid(self) and IsValid(self:GetActiveWeapon()) and !self:IsDrinking("ttt_perk_doubletap") then
              self:GivetheDoubleTap()
              timer.Remove("MaketheDoubleTapDrink" .. self:EntIndex())
            end
          end)
      else
        self:GivetheDoubleTap()
      end
    end
  end

  function plymeta:GivetheDoubleTap()
    self:Give("ttt_perk_doubletap")
    self:SelectWeapon("ttt_perk_doubletap")
    if self:HasWeapon("ttt_perk_doubletap") then
      self:GetWeapon("ttt_perk_doubletap"):DrinkTheBottle()
    end
  end

  hook.Add("TTTOrderedEquipment", "TTTDoubleTap", function(ply, equipment, is_item)
      if is_item == EQUIP_DOUBLETAP then
        ply:CanDrinkDoubleTap()
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
