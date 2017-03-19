if SERVER then
  AddCSLuaFile()
  resource.AddFile("vgui/ttt/icon_asc.vmt")
  resource.AddWorkshop("672173225")
  util.AddNetworkString("ASCBuyed")
  util.AddNetworkString("ASCKill")
  util.AddNetworkString("ASCError")
  util.AddNetworkString("ASCRespawn")
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
  hook.Add("TTTBoughtItem", "TTTASC2", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_ASC)) then
        yCoordinate = getYCoordinate(EQUIP_ASC)
      end
    end)
  local material = Material("vgui/ttt/perks/hud_asc.png")
  hook.Add("HUDPaint", "TTTASC", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_ASC)) then
        surface.SetMaterial(material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(20, yCoordinate, 64, 64)
      end
    end)

end

local function getNextFreeID()
  local freeID, i = 1, 1
  while (freeID == 1) do
    if (!GetEquipmentItem(ROLE_DETECTIVE, i)
      and !GetEquipmentItem(ROLE_TRAITOR, i)) then
      freeID = i
    end
    i = i * 2
  end

  return freeID
end

EQUIP_ASC = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or getNextFreeID()

local ASecondChance = {
  id = EQUIP_ASC,
  loadout = false,
  type = "item_passive",
  material = "vgui/ttt/icon_asc",
  name = "A Second Chance",
  desc = "Life for a second time but only with a given Chance. \nYour Chance will change per kill.\nIt also works if the round should end.",
  hud = true
}

local detectiveCanUse = CreateConVar("ttt_secondchance_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the Second Chance.")
local traitorCanUse = CreateConVar("ttt_secondchance_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the Second Chance.")

if (detectiveCanUse:GetBool()) then
  table.insert(EquipmentItems[ROLE_DETECTIVE], ASecondChance)
end
if (traitorCanUse:GetBool()) then
  table.insert(EquipmentItems[ROLE_TRAITOR], ASecondChance)
end

if SERVER then
  --local keepweapons = CreateConVar("ttt_secondchance_weapons",0,{FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED},"Should the Owner of the Second Chance get the weapons back?")
    /*local function ASCStoreWeapons(ply)
    ply.ASCWeapons = {}
    for k,v in pairs(ply:GetWeapons()) do
      if IsValid(v) and (v.Kind == WEAPON_HEAVY or v.Kind == WEAPON_PISTOL or v.Kind == WEAPON_EQUIP1 or v.Kind == WEAPON_EQUIP2 or v.Kind == WEAPON_GRENADE or v.Kind == WEAPON_ROLE) then
        table.insert(ply.ASCWeapons, {cl = v:GetClass(), c1 = v:Clip1(), c2 = v:Clip2()})
      end
    end
  end

  local function ASCRetrieveWeapons(ply)
    for k,v in pairs(ply.ASCWeapons) do
        ply:Give(v.cl)
        local wep = ply:GetWeapon(v.cl)
        if IsValid(wep) then
          wep:SetClip1(v.c1)
          wep:SetClip2(v.c2)
          if wep.Kind == WEAPON_HEAVY then
          ply:SelectWeapon(v.cl)
          end
        end
    end
    table.Empty(ply.ASCWeapons)
  end*/


  hook.Add("TTTOrderedEquipment", "TTTASC", function(ply, equipment, is_item)
      if is_item == EQUIP_ASC then
        ply.shouldasc = true
        if ply:GetRole() == ROLE_TRAITOR then
          ply.SecondChanceChance = 25
        elseif ply:GetRole() == ROLE_DETECTIVE then
          ply.SecondChanceChance = 50
        end
        local chance = math.Clamp(math.Round(ply.SecondChanceChance, 0), 0, 99)
        net.Start("ASCBuyed")
        net.WriteInt(chance, 8)
        net.Send(ply)
      end
    end)

  local plymeta = FindMetaTable( "Player" );

  function SecondChance( victim, inflictor, attacker)
    local SecondChanceRandom = math.random(1,100)
    if victim.shouldasc == true and SecondChanceRandom < math.Clamp(math.Round(victim.SecondChanceChance, 0), 0, 99) then
      victim.NOWINASC = true
      victim:SetNWInt("ASCthetimeleft", 10)
      timer.Create("TTTASC" .. victim:EntIndex() , 1 ,10, function()
          if IsValid(victim) then
            victim:SetNWInt("ASCthetimeleft", victim:GetNWInt("ASCthetimeleft") - 1)
            if ( victim:GetNWInt("ASCthetimeleft") <= 9 ) then
              victim:SetNWBool("ASCCanRespawn", true)
            end
            if ( victim:GetNWInt("ASCthetimeleft") <= 0 ) then
              victim:ASCHandleRespawn(true)
            end
          end
        end )
      net.Start("ASCRespawn")
      net.WriteBit(true)
      net.Send(victim)
    elseif victim.shouldasc == true and SecondChanceRandom > math.Clamp(math.Round(victim.SecondChanceChance, 0), 0, 99) then
      victim.shouldasc = false
      --if keepweapons:GetBool() then
      --  table.Empty(victim.ASCWeapons)
      --end
      net.Start("ASCRespawn")
      net.WriteBit(false)
      net.Send(victim)
    end
  end

  local Positions = {}
  for i = 0,360,22.5 do table.insert( Positions, Vector(math.cos(i),math.sin(i),0) ) end -- Populate Around Player
  table.insert(Positions, Vector(0, 0, 1)) -- Populate Above Player

  function FindASCPosition(ply) -- I stole a bit of the Code from NiandraLades because its good
    local size = Vector(32, 32, 72)

    local StartPos = ply:GetPos() + Vector(0, 0, size.z / 2)

    local len = #Positions

    for i = 1, len do
      local v = Positions[i]
      local Pos = StartPos + v * size * 1.5

      local tr = {}
      tr.start = Pos
      tr.endpos = Pos
      tr.mins = size / 2 * -1
      tr.maxs = size / 2
      local trace = util.TraceHull(tr)

      if (!trace.Hit) then
        return Pos - Vector(0, 0, size.z / 2)
      end
    end

    return false
  end

  function plymeta:ASCHandleRespawn(corpse)
  if !IsValid(self) then return end
    local body = FindCorpse(self)

    if !IsValid(body) then
    	if SERVER then
    		net.Start("ASCError")
    		net.Send(self)
    	end

    	return
    end

    if corpse then
    	local spawnPos = FindASCPosition(body)

    	if !spawnPos then
    		if SERVER then
    			net.Start("ASCError")
    			net.Send(self)
    		end

    		return
    	end

    	self:SpawnForRound(true)
    	self:SetPos(spawnPos)
    	self:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
    else
    	self:SpawnForRound(true)
    end
    self:SetNWBool("ASCCanRespawn", false)
    self.shouldasc = false
    self.NOWINASC = false
    local credits = CORPSE.GetCredits(body, 0)
    DamageLog("SecondChance: " .. self:Nick() .. " has been respawned.")
    self:SetNWInt("ASCthetimeleft", 10)
    self:SetCredits(credits)
    timer.Remove("TTTASC" .. self:EntIndex())
    body:Remove()
    --if keepweapons:GetBool() and istable(self.ASCWeapons) then
    --  ASCRetrieveWeapons(self)
    --end
    return true
  end

  hook.Add( "KeyPress", "ASCRespawn", function( ply, key )
      if ply:GetNWBool("ASCCanRespawn") then
        if key == IN_RELOAD then
          ply:ASCHandleRespawn(true)
        elseif key == IN_JUMP then
          ply:ASCHandleRespawn(false)
        end
      end
    end )

  function CUSTOMWIN()
    for k,v in pairs(player.GetAll()) do
      if v.NOWINASC == true then return WIN_NONE end
    end
  end

  function FindCorpse(ply) -- From TTT Ulx Commands, sorry
    for _, ent in pairs( ents.FindByClass( "prop_ragdoll" )) do
      if ent.uqid == ply:UniqueID() and IsValid(ent) then
        return ent or false
      end
    end
  end

  function ResettinAsc()
    for k,v in pairs(player.GetAll()) do
      v.shouldasc = false
      v.NOWINASC = false
      v:SetNWBool("ASCCanRespawn", false)
      v:SetNWInt("ASCthetimeleft", 10)
      v.SecondChanceChance = 0
      timer.Remove("TTTASC" .. v:EntIndex())
      --if keepweapons:GetBool() and istable(v.ASCWeapons) then
      --  table.Empty(v.ASCWeapons)
      --end
    end
  end

  function CheckifAsc(ply, attacker, dmg)
    if IsValid(attacker) and ply != attacker and attacker:IsPlayer() and attacker:HasEquipmentItem(EQUIP_ASC) then
      if attacker:GetRole() == ROLE_TRAITOR and ply:GetRole() == ROLE_INNOCENT or ply:GetRole() == ROLE_DETECTIVE then
        attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance + 15, 0, 99)
        net.Start("ASCKill")
        net.WriteInt(attacker.SecondChanceChance,8)
        net.Send(attacker)
      elseif attacker:GetRole() == ROLE_DETECTIVE and ply:GetRole() == ROLE_TRAITOR then
        attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance + 25, 0, 99)
        net.Start("ASCKill")
        net.WriteInt(attacker.SecondChanceChance,8)
        net.Send(attacker)
      end
    end
    --if keepweapons:GetBool() and IsValid(ply) and ply:HasEquipmentItem(EQUIP_ASC) then
    --  ASCStoreWeapons(ply)
    --  ply:StripWeapons()
    --end
  end
end

if CLIENT then

  function DrawASCHUD()
    if LocalPlayer():GetNWBool("ASCCanRespawn") then
      draw.RoundedBox( 20, ScrW() / 2-945, ScrH() / 2-440, 300 , 100 ,Color(255,80,80,255) )
      surface.SetDrawColor(255,255,255,255)
      local w = LocalPlayer():GetNWInt("ASCthetimeleft") * 20
      draw.SimpleText("Time Left: " .. LocalPlayer():GetNWInt("ASCthetimeleft"), DermaDefault, ScrW() / 2-800, ScrH() / 2-390, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
      draw.SimpleText("Press R to Respawn on your Corpse,", DermaDefault, ScrW() / 2-800, ScrH() / 2-375, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
      draw.SimpleText("Press Space to Respawn on Spawn", DermaDefault, ScrW() / 2-800, ScrH() / 2-360, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
      surface.DrawRect(ScrW() / 2-900, ScrH() / 2-420, w, 20)
      surface.SetDrawColor(0,0,0,255)
      surface.DrawOutlinedRect(ScrW() / 2-900, ScrH() / 2-420, 200, 20)
    end
  end

  hook.Add("HUDPaint", "DrawASCHUD", DrawASCHUD)
end

hook.Add("DoPlayerDeath", "ASCChance", CheckifAsc )
hook.Add("TTTPrepareRound", "ASCRESET", ResettinAsc )
hook.Add("PlayerDeath", "ASCCHANCE", SecondChance )
hook.Add("TTTCheckForWin", "ASCCHECKFORWIN", CUSTOMWIN)

hook.Add("PlayerDisconnected", "ASCDisconnect", function(ply)
    if IsValid(ply) then
      ply.shouldasc = false
      ply:SetNWInt("ASCthetimeleft", 10)
      ply.NOWINASC = false
      ply.SecondChanceChance = 0
      ply:SetNWBool("ASCCanRespawn", false)
      timer.Remove("TTTASC" .. ply:EntIndex())
    end
  end )

hook.Add("PlayerSpawn","ASCReset", function(ply)
    if IsValid(ply) and ply:IsTerror() then
      ply.shouldasc = false
      ply:SetNWInt("ASCthetimeleft", 10)
      ply.NOWINASC = false
      ply.SecondChanceChance = 0
      ply:SetNWBool("ASCCanRespawn", false)
      timer.Remove("TTTASC" .. ply:EntIndex())
    end
  end )

if CLIENT then
  net.Receive("ASCBuyed",function()
      local chance = net.ReadInt(8)
      chat.AddText("SecondChance: ", Color(255,255,255), "You will be revived with a chance of " .. chance .. "% !" )
      chat.PlaySound()
    end)
  net.Receive("ASCKill",function()
      local chance = net.ReadInt(8)
      chat.AddText("SecondChance: ", Color(255,255,255), "Your chance of has been changed to " .. chance .. "% !" )
      chat.PlaySound()
    end)
  net.Receive("ASCRespawn",function()
      local respawn = net.ReadBool()
      if respawn then
        chat.AddText("SecondChance: ", Color(255,255,255), "Press Reload to spawn at your body. Press Space to spawn at the map spawn." )
      else
        chat.AddText("SecondChance: ", Color(255,255,255), "You will not be revived." )
      end
      chat.PlaySound()
    end)
  net.Receive("ASCError",function()
      chat.AddText("SecondChance ", COLOR_RED, "ERROR", COLOR_WHITE, ": " , Color(255,255,255), "Body not found! No respawn.")
      chat.PlaySound()
    end)

    hook.Add("TTTBodySearchEquipment", "ASCCorpseIcon", function(search, eq)
        search.eq_asc = util.BitSet(eq, EQUIP_ASC)
      end )

    hook.Add("TTTBodySearchPopulate", "ASCCorpseIcon", function(search, raw)
        if (!raw.eq_asc) then
          return end

          local highest = 0
          for _, v in pairs(search) do
            highest = math.max(highest, v.p)
          end

          search.eq_asc = {img = "vgui/ttt/icon_asc", text = "They maybe will have a Second Chance...", p = highest + 1}
      end )
end
