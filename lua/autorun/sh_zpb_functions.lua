if SERVER then
  AddCSLuaFile()
  resource.AddFile("sound/perks/open.wav")
  resource.AddFile("sound/perks/smash.wav")
  resource.AddFile("sound/perks/drink.wav")
  resource.AddFile("sound/perks/burp.wav")
  util.AddNetworkString("ZPBResetMaterials")
end

local Perks = {
  "PHD",
  "StaminUp",
  "Juggernog",
  "Speed",
  "DoubleTap"
}

local plymeta = FindMetaTable("Player")

function plymeta:IsDrinking()
  for _,perk in pairs(Perks) do
    perk = "ttt_perk_" .. string.lower(perk)
    if IsValid(self:GetActiveWeapon()) then
      if perk == self:GetActiveWeapon():GetClass() then
        return true
      end
    else
      return false
    end
  end
  return false
end

hook.Add("TTTPrepareRound", "ZPBResetMaterial", function()
  if SERVER then
    net.Start("ZPBResetMaterials")
    net.Broadcast()
  end
end)

hook.Add("PlayerSpawn", "ZPBResetMaterial", function(ply)
  if IsValid(ply) then
    net.Start("ZPBResetMaterials")
    net.Send(ply)
  end
end)

net.Receive("ZPBResetMaterials", function()
  if CLIENT and IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetViewModel()) then
    local vm = LocalPlayer():GetViewModel()
    if oldmat then
      vm:SetMaterial(oldmat)
      oldmat = nil
    else
      vm:SetMaterial("")
    end
  end
end)
