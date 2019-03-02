if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/ic_phd.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_phd.png")
end

ITEM.hud  = Material("vgui/ttt/perks/hud_phd_ttt2.png")

ITEM.EquipMenuData = {
  type = "item_passive",
  name = "PHD Flopper",
  desc = "PHD Flopper Perk.\nAutomatically drinks perk to become \nimmune to fall damage,\nexplosion damage, and create an explosion\nwhere you land.",
}

ITEM.credits = 1
ITEM.material = "vgui/ttt/ic_phd"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

if SERVER then

  function ITEM:Bought(ply)
      ply:Give("ttt_perk_phd")
  end

  hook.Add("TTTCanOrderEquipment", "TTTPHD2", function(ply, id)
    if id == "item_ttt_phd" and ply:IsDrinking() then
      return false
    end
  end)
end
