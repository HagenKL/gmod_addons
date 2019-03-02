if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/ic_juggernog.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_juggernog.png")
end

ITEM.hud  = Material("vgui/ttt/perks/hud_juggernog_ttt2.png")

ITEM.EquipMenuData = {
  type = "item_passive",
  name = "Juggernog",
  desc = "Juggernog Perk.\nAutomatically drinks perk to get \nthe maximum health avaible!",
}

ITEM.credits = 1
ITEM.material = "vgui/ttt/ic_juggernog"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

if SERVER then

  function ITEM:Bought(ply)
      ply:Give("ttt_perk_juggernog")
  end

  hook.Add("TTTCanOrderEquipment", "TTTJuggernog2", function(ply, id)
    if id == "item_ttt_juggernog" and ply:IsDrinking() then
      return false
    end
  end)
end
