if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/icon_speed.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_speed.png")
  util.AddNetworkString("DrinkingtheSpeed")
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
  hook.Add("TTTBoughtItem", "TTTSpeed", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_SPEED)) then
        yCoordinate = getYCoordinate(EQUIP_SPEED)
      end
    end)
  local material = Material("vgui/ttt/perks/hud_speed.png")
  hook.Add("HUDPaint", "TTTSpeed", function()
      if LocalPlayer():GetNWBool("SpeedActive", false) and LocalPlayer():HasEquipmentItem(EQUIP_SPEED) then
        surface.SetMaterial(material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(20, yCoordinate, 64, 64)
      end
    end)
    LANG.AddToLanguage("english", "item_speed_name", "Speed Cola")
    LANG.AddToLanguage("english", "item_speed_desc", "Speed Cola Perk.\nAutomatically drinks perk to get \ndouble the reload speed.")
end

EQUIP_SPEED = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 512

if SERVER then

  local plymeta = FindMetaTable("Player")
  function plymeta:CanDrinkSpeed()
    if IsValid(self) and self:IsTerror() then
      if IsValid(self:GetActiveWeapon()) and self:IsDrinking("ttt_perk_speed") then
        timer.Create("MaketheSpeedDrink" .. self:EntIndex(),0.5,0, function()
            if IsValid(self) and IsValid(self:GetActiveWeapon()) and !self:IsDrinking("ttt_perk_speed") then
              self:GivetheSpeed()
              timer.Remove("MaketheSpeedDrink" .. self:EntIndex())
            end
          end)
      else
        self:GivetheSpeed()
      end
    end
  end

  function plymeta:GivetheSpeed()
    self:Give("ttt_perk_speed")
    self:SelectWeapon("ttt_perk_speed")
    if self:HasWeapon("ttt_perk_speed") then
      self:GetWeapon("ttt_perk_speed"):DrinkTheBottle()
    end
  end

  hook.Add("TTTOrderedEquipment", "TTTSpeed", function(ply, equipment, is_item)
      if is_item == EQUIP_SPEED then
        ply:CanDrinkSpeed()
      end
    end)
    hook.Add("TTTPrepareRound", "TTTSpeedResettin", function()
      for k,v in pairs(player.GetAll()) do
        timer.Remove("MaketheSpeedDrink" .. v:EntIndex())
      end
    end)
end

if CLIENT then
  hook.Add("TTTBodySearchEquipment", "SpeedCorpseIcon", function(search, eq)
      search.eq_speed = util.BitSet(eq, EQUIP_SPEED)
    end )

  hook.Add("TTTBodySearchPopulate", "SpeedCorpseIcon", function(search, raw)
      if (!raw.eq_speed) then
        return end

        local highest = 0
        for _, v in pairs(search) do
          highest = math.max(highest, v.p)
        end

        search.eq_speed = {img = "vgui/ttt/icon_speed", text = "They drunk a Speed Cola.", p = highest + 1}
      end )
  end
