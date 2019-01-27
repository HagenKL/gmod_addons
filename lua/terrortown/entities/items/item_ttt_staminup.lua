if true then return end

if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/ic_staminup.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_staminup.png")
end

ITEM.hud  = "vgui/ttt/perks/hud_staminup.png"

ITEM.EquipMenuData = {
  type = "item_passive",
  name = "Stamin-Up",
  desc = "Stamin-Up Perk.\nAutomatically drinks perk to greatly increase\nwalk speed!",
}

ITEM.credits = 1
ITEM.material = "vgui/ttt/ic_staminup"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

if SERVER then

  function ITEM:Bought(ply)
      ply:Give("ttt_perk_staminup")
  end

  hook.Add("TTTCanOrderEquipment", "TTTStaminup2", function(ply, id)
    if id == "item_ttt_staminup" and ply:IsDrinking() then
      return false
    end
  end)
end
