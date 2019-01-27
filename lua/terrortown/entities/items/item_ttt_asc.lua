if SERVER then
  AddCSLuaFile()
  resource.AddFile("vgui/ttt/icon_asc.vmt")
  resource.AddWorkshop("672173225")
  util.AddNetworkString("ASCBuyed")
  util.AddNetworkString("ASCKill")
  util.AddNetworkString("ASCError")
  util.AddNetworkString("ASCRespawn")
  util.AddNetworkString("ASCRespawned")
end


ITEM.hud = Material("vgui/ttt/perks/hud_asc.png")
ITEM.EquipMenuData = {
  type = "item_passive",
  name = "A Second Chance",
  desc = "Life for a second time but only with a given Chance. \nYour Chance will change per kill.\nIt also works if the round should end.",
}
ITEM.material = "vgui/ttt/icon_asc"
ITEM.corpseDesc = "They maybe will have a Second Chance..."
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}
ITEM.oldId = EQUIP_ASC

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


  hook.Add("TTTOrderedEquipment", "TTTASC", function(ply, id, is_item)
      if id == "ttt_a_second_chance" then
        ply.shouldasc = true
		if ply:GetRole() == ROLE_TRAITOR or ply:GetRole() == ROLE_JACKAL or ply:GetRole() == ROLE_SIDEKICK then
			ply.SecondChanceChance = math.random(15,25)
		else
			ply.SecondChanceChance = math.random(20,35)
		end
		  
        for k,v in pairs(ply.kills) do
          local victim = player.GetBySteamID64(v)
		  if IsValid(victim) and not victim:Alive() then
			if ply:IsInTeam(victim) then
				ply.SecondChanceChance = math.Clamp(ply.SecondChanceChance - math.random(5,15), 0, 99)
			else
				if ply:GetRole() == ROLE_TRAITOR or ply:GetRole() == ROLE_JACKAL or ply:GetRole() == ROLE_SIDEKICK then
					ply.SecondChanceChance = math.Clamp(ply.SecondChanceChance + math.random(10,20), 0, 99)
				else
					ply.SecondChanceChance = math.Clamp(ply.SecondChanceChance + math.random(15,25), 0, 99)
				end
			end
		  end
        end
        net.Start("ASCBuyed")
        net.WriteInt(ply.SecondChanceChance, 8)
        net.Send(ply)
      end
    end)

  local plymeta = FindMetaTable( "Player" );

  function SecondChance( victim, inflictor, attacker)
	if not victim.SecondChanceChance then return end
    local SecondChanceRandom = math.random(1,100)
    local PlayerChance = math.Clamp(math.Round(victim.SecondChanceChance, 0), 0, 99)
    if victim.shouldasc == true and SecondChanceRandom <= PlayerChance then
      victim.NOWINASC = true
      victim.ASCTimeLeft = CurTime() + 10
      net.Start("ASCRespawn")
      net.WriteBit(true)
      net.Send(victim)
    elseif victim.shouldasc == true and SecondChanceRandom > PlayerChance then
      victim.shouldasc = false
      --if keepweapons:GetBool() then
      --  table.Empty(victim.ASCWeapons)
      --end
      net.Start("ASCRespawn")
      net.WriteFloat(victim.ASCTimeLeft)
      net.WriteBool(false)
      net.Send(victim)
    end
  end

  local function ASCThink()
    for k,ply in pairs(player.GetAll()) do
      if ply.NOWINASC then
        if ply.ASCTimeLeft <= CurTime() + 8 then
          ply.ASCCanRespawn = true
        end
        if ply.ASCTimeLeft <= CurTime() then
          ply:ASCHandleRespawn(true)
        end
      end
    end
  end

  hook.Add("Think", "ASCThink", ASCThink)

  local Positions = {}
  for i = 0,360,22.5 do table.insert( Positions, Vector(math.cos(i),math.sin(i),0) ) end -- Populate Around Player
  table.insert(Positions, Vector(0, 0, 1)) -- Populate Above Player

  local function FindASCPosition(ply) -- I stole a bit of the Code from NiandraLades because its good
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

  local function FindCorpse(ply) -- From TTT Ulx Commands, sorry
    for _, ent in pairs( ents.FindByClass( "prop_ragdoll" )) do
      if ent.uqid == ply:UniqueID() and IsValid(ent) then
        return ent or false
      end
    end
  end

  function plymeta:ASCHandleRespawn(corpse)
  if !IsValid(self) then return end
    local body = FindCorpse(self)

    if !IsValid(body) or body:IsOnFire() then
      if SERVER then
        net.Start("ASCError")
        net.WriteBool(false)
        net.Send(self)
      end
      self.shouldasc = false
      self.NOWINASC = false
      timer.Remove("TTTASC" .. self:EntIndex())
	    self.ASCCanRespawn = false
      self:SetNWInt("ASCthetimeleft", 10)
      return
    end

    if corpse then
      local spawnPos = FindASCPosition(body)

      if !spawnPos then
        if SERVER then
          net.Start("ASCError")
          net.WriteBool(true)
          net.Send(self)
        end
        self:ASCHandleRespawn(false)
        return
      end

      self:SpawnForRound(true)
      self:SetPos(spawnPos)
      self:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
    else
      self:SpawnForRound(true)
    end

    self:SetMaxHealth(100)
    self.ASCCanRespawn = false
    self.ASCTimeLeft = 0
    self.shouldasc = false
    self.NOWINASC = false
    local credits = CORPSE.GetCredits(body, 0)
    self:SetCredits(credits)
    body:Remove()
    DamageLog("SecondChance: " .. self:Nick() .. " has been respawned.")
    net.Start("ASCRespawned")
    net.Send(self)
    --if keepweapons:GetBool() and istable(self.ASCWeapons) then
    --  ASCRetrieveWeapons(self)
    --end
  end

  hook.Add( "KeyPress", "ASCRespawn", function( ply, key )
      if ply.ASCCanRespawn then
        if key == IN_RELOAD then
          ply:ASCHandleRespawn(true)
        elseif key == IN_JUMP then
          ply:ASCHandleRespawn(false)
        end
      end
    end )

  local function CUSTOMWIN()
    for k,v in pairs(player.GetAll()) do
      if v.NOWINASC == true then return WIN_NONE end
    end
  end

  local function CheckifAsc(ply, attacker, dmg)
    if IsValid(attacker) and ply != attacker and attacker:IsPlayer() and attacker:HasEquipmentItem("ttt_a_second_chance") then
      --if (attacker:GetTraitor() or (attacker.IsEvil and attacker:IsEvil())) and ((ply:GetRole() == ROLE_INNOCENT or ply:GetRole() == ROLE_DETECTIVE) or (ply.GetGood and (ply:GetGood() or ply:IsNeutral()))) then
        --attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance + math.random(10,20), 0, 99)
      --elseif (attacker:GetRole() == ROLE_DETECTIVE or (attacker.GetGood and attacker:GetGood())) and (ply:GetTraitor() or (ply.IsEvil and (ply:IsEvil() or ply:IsNeutral()))) then
       -- attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance + math.random(20,30), 0, 99)
      --elseif attacker.IsNeutral and attacker:IsNeutral() and (ply:GetGood() or ply:GetEvil()) then
        --attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance + math.random(15,25), 0, 99)
      --end]
	  if attacker:IsInTeam(ply) then
		attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance - math.random(5,15), 0, 99)
	  else
		if attacker:GetRole() == ROLE_TRAITOR or attacker:GetRole() == ROLE_JACKAL or attacker:GetRole() == ROLE_SIDEKICK then
			attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance + math.random(10,20), 0, 99)
		else
			attacker.SecondChanceChance = math.Clamp(attacker.SecondChanceChance + math.random(15,25), 0, 99)
		end
	  end
	  
      net.Start("ASCKill")
      net.WriteInt(attacker.SecondChanceChance,8)
      net.Send(attacker)
    end
    --if keepweapons:GetBool() and IsValid(ply) and ply:HasEquipmentItem(EQUIP_ASC) then
    --  ASCStoreWeapons(ply)
    --  ply:StripWeapons()
    --end
  end

  hook.Add("DoPlayerDeath", "ASCChance", CheckifAsc )
  hook.Add("PlayerDeath", "ASCCHANCE", SecondChance )
  hook.Add("TTTCheckForWin", "ASCCHECKFORWIN", CUSTOMWIN)
end

local function ResettinAsc()
	for k,v in pairs(player.GetAll()) do
		v.ASCCanRespawn = false
		v.ASCTimeLeft = 0
	  	if SERVER then
			v.SecondChanceChance = 0
		  	v.shouldasc = false
	  		v.NOWINASC = false
		  --if keepweapons:GetBool() and istable(v.ASCWeapons) then
		  --  table.Empty(v.ASCWeapons)
		  --end
		end
	end
end

hook.Add("TTTPrepareRound", "ASCRESET", ResettinAsc )

if CLIENT then
  local width = 300
  local height = 100
  local color = Color(255,80,80,255)
  function DrawASCHUD()
    if LocalPlayer().ASCCanRespawn and LocalPlayer().ASCTimeLeft > CurTime() then
      local x = ScrW()/2 - width/2
      local y = ScrH()/3 - height
      draw.RoundedBox( 20, x, y, 300 , 100 , color)
      surface.SetDrawColor(255,255,255,255)
      local w = (LocalPlayer().ASCTimeLeft - CurTime()) * 20
      draw.SimpleText("Time Left: " .. math.Round(LocalPlayer().ASCTimeLeft - CurTime(),1), DermaDefault, x + width/2, y + height/1.2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
      draw.SimpleText("Press R to Respawn on your Corpse", DermaDefault, x + width/2, y + height/6, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
      draw.SimpleText("Press Space to Respawn on Map Spawn", DermaDefault, x + width/2, y + height/3, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
      surface.DrawRect(x + width/6, y + height/2, w, 20)
      surface.SetDrawColor(0,0,0,255)
      surface.DrawOutlinedRect(x + width/6, y + height/2, 200, 20)
      if LocalPlayer().ASCTimeLeft > CurTime() + 8 then
        surface.SetDrawColor(COLOR_RED)
        surface.DrawLine(x, y, x + 300, y + 100)
        surface.DrawLine(x + 300, y, x, y + 100)
      end
    end
  end

  hook.Add("HUDPaint", "DrawASCHUD", DrawASCHUD)
end

hook.Add("PlayerDisconnected", "ASCDisconnect", function(ply)
    if IsValid(ply) then
      ply.shouldasc = false
      ply.ASCTimeLeft = 0
      ply.NOWINASC = false
      ply.SecondChanceChance = 0
      ply.ASCCanRespawn = false
    end
  end )

hook.Add("PlayerSpawn","ASCReset", function(ply)
    if IsValid(ply) and ply:IsTerror() then
      ply.shouldasc = false
      ply.ASCTimeLeft = 0
      ply.NOWINASC = false
      ply.SecondChanceChance = 0
      ply.ASCCanRespawn = false
    end
  end )

if CLIENT then
  net.Receive("ASCRespawned",function()
    LocalPlayer().ASCCanRespawn = false
    LocalPlayer().ASCTimeLeft = 0
  end)
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
	    LocalPlayer().ASCCanRespawn = true
		LocalPlayer().ASCTimeLeft = CurTime() + 10
        chat.AddText("SecondChance: ", Color(255,255,255), "Press Reload to spawn at your body. Press Space to spawn at the map spawn." )
      else
        chat.AddText("SecondChance: ", Color(255,255,255), "You will not be revived." )
      end
      chat.PlaySound()
    end)
  net.Receive("ASCError",function()
      local spawnpos = net.ReadBool()
      if spawnpos then
        chat.AddText("SecondChance ", COLOR_RED, "ERROR", COLOR_WHITE, ": " , Color(255,255,255), "No Valid Spawnpoints! Spawning at Map Spawn.")
      else
        chat.AddText("SecondChance ", COLOR_RED, "ERROR", COLOR_WHITE, ": " , Color(255,255,255), "Body not found or on fire, so you cant revive yourself.")
      end
      chat.PlaySound()
    end)

end