local function SendDeathGrip(ply)
  net.Start("TTTDeathGrip")
  net.WriteEntity(ply.DeathGrip)
  net.Send(ply)
end

local function SendDeathGripReset(ply)
  net.Start("TTTDeathGripReset")
  net.Send(ply)
end

local function SendDeathGripMessage(ply)
  net.Start("TTTDeathGripMessage")
  net.Send(ply)
end

local function SelectDeathGripPlayers()
  if math.random(0,1) < 0.75 and #util.GetAlivePlayers() > 2 then
    local players = util.GetAlivePlayers() // All alive people

    local index = math.random(1, #players)
    local pick = players[index]
    table.remove(players, index)

    local index2 = math.random(1, #players)
    local pick2 = players[index2]
    table.remove(players, index2) // Pick two random

    pick.DeathGrip = pick2
    pick2.DeathGrip = pick // assign them to each other

    SendDeathGrip(pick)
    SendDeathGrip(pick2)
  end
end

local function DeathGrip(ply, inflictor, attacker)
  if ply.DeathGrip and IsValid(ply.DeathGrip) and ply.DeathGrip:IsTerror() then
    local temp = ply.DeathGrip // prevent infinite loop
    SendDeathGripReset(ply)
    SendDeathGripReset(ply.DeathGrip)
    ply.DeathGrip.DeathGrip = nil
    ply.DeathGrip = nil
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(10000)
    dmginfo:SetAttacker(game.GetWorld())
    dmginfo:SetDamageType(DMG_GENERIC)
    temp:TakeDamageInfo(dmginfo) // kill the other guy
    SendDeathGripMessage(temp)
  end
end

local function BreakDeathGrip(ply)
  if #util.GetAlivePlayers() < 3 then
    for k,v in pairs(player.GetAll()) do
      v.DeathGrip = nil
      SendDeathGripReset(v)
    end
  end
end

local function ResetDeathGrips()
  for k,v in pairs(player.GetAll()) do
    v.DeathGrip = nil // Reset
  end
end

hook.Add("PostPlayerDeath","TTTDeathGrip", BreakDeathGrip)
hook.Add("PlayerDeath", "TTTDeathGrip", DeathGrip)
hook.Add("TTTBeginRound", "TTTDeathGrip", SelectDeathGripPlayers)
hook.Add("TTTPrepareRound", "TTTDeathGrip", ResetDeathGrips)
