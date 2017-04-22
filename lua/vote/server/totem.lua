--if !GetGlobalBool("ttt_totem", true) then print("TTT Totem is not enabled on this Server, type ttt_totem 1 in Server Console to enable!") return end

function TTTVote.PlaceTotem(len, sender)
  local ply = sender
  if !IsValid(ply) or !ply:IsTerror() then return end
  if !ply:GetNWBool("CanSpawnTotem", true) or IsValid(ply:GetNWEntity("Totem",NULL)) or ply:GetNWBool("PlacedTotem") then
    net.Start("TTTTotem")
    net.WriteInt(1,8)
    net.Send(ply)
    return
  end
  if !ply:OnGround() then
    net.Start("TTTTotem")
    net.WriteInt(2,8)
    net.Send(ply)
    return
  end

  if ply:IsInWorld() then
    local totem = ents.Create("ttt_totem")
    if IsValid(totem) then
      totem:SetAngles(ply:GetAngles())

      totem:SetPos(ply:GetPos())
      totem:SetOwner(ply)
      totem:Spawn()

      ply:SetNWBool("CanSpawnTotem",false)
      ply:SetNWBool("PlacedTotem", true)
      ply:SetNWEntity("Totem",totem)
      net.Start("TTTTotem")
      net.WriteInt(3,8)
      net.Send(ply)
      TTTVote.TotemUpdate()
	  if sender:GetNWInt("VoteCounter",0) >= 3 then
		totem:AddHalos()
	  end
    end
  end
end

function TTTVote.HasTotem(ply)
  return IsValid(ply:GetNWEntity("Totem", NULL))
end

function TTTVote.TotemUpdate()
  if (GetRoundState() == ROUND_ACTIVE or GetRoundState() == ROUND_POST) and TTTVote.AnyTotems then

    TTTVote.totems = {}
    for k,v in pairs(player.GetAll()) do
      if (v:IsTerror() or !v:Alive()) and (TTTVote.HasTotem(v) or v:GetNWBool("CanSpawnTotem", false)) then
        table.insert(TTTVote.totems, v)
      end
    end



    if #TTTVote.totems >= 1 then
      TTTVote.AnyTotems = true
    else
      TTTVote.AnyTotems = false
      net.Start("TTTTotem")
      net.WriteInt(8,8)
      net.Broadcast()
      return
    end

    TTTVote.innototems = {}

    for k,v in pairs(TTTVote.totems) do
      if v:IsDetective() or v:GetRole() == ROLE_INNOCENT then
        table.insert(TTTVote.innototems, v)
      end
    end

    if TTTVote.AnyTotems and #TTTVote.innototems == 0 then
      TTTVote.DestroyAllTotems()
    end
  end
end

function TTTVote.DestroyAllTotems()
  for k,v in pairs(ents.FindByClass("ttt_totem")) do
    v:FakeDestroy()
  end
  for k,v in pairs(player.GetAll()) do
    v:SetNWBool("CanSpawnTotem", false)
  end
  TTTVote.TotemUpdate()
 end

function TTTVote.TotemSuffer()
  if GetRoundState() == ROUND_ACTIVE and TTTVote.AnyTotems then
    for k,v in pairs(player.GetAll()) do
      if v:IsTerror() and !v:GetNWBool("PlacedTotem", false) and v.TotemSuffer then
        if v.TotemSuffer == 0 then
          v.TotemSuffer = CurTime() + 10
          v.DamageNotified = false
        elseif v.TotemSuffer <= CurTime() then
          if !v.DamageNotified then
            net.Start("TTTTotem")
            net.WriteInt(6,8)
            net.Send(v)
            v.DamageNotified = true
          end
          v:TakeDamage(1,v,v)
          v.TotemSuffer = CurTime() + 0.2
        end
      elseif v:IsTerror() and (v:GetNWBool("PlacedTotem", true) or !v.TotemSuffer) then
        v.TotemSuffer = 0
        v.DamageNotified = false
      end
    end
  end
end

function TTTVote.GiveTotemHunterCredits(ply,totem)
  LANG.Msg(ply, "credit_ht_all", {num = 1})
  ply:AddCredits(1)
end

function TTTVote.ResetTotems()
  for k,v in pairs(player.GetAll()) do
    v:SetNWBool("CanSpawnTotem", true)
    v:SetNWBool("PlacedTotem", false)
    v:SetNWEntity("Totem", NULL)
    v.TotemSuffer = 0
    v.DamageNotified = false
    v.totemuses = 0
  end
  TTTVote.AnyTotems = true
end

function TTTVote.ResetSuffer()
  for k,v in pairs(player.GetAll()) do
    v.TotemSuffer = 0
  end
end

function TTTVote.DestroyTotem(ply)
  if GetRoundState() == ROUND_ACTIVE then
    ply:SetNWBool("CanSpawnTotem", false)
    TTTVote.TotemUpdate()
  end
end

net.Receive("TTTVotePlaceTotem", TTTVote.PlaceTotem)
hook.Add("TTTPrepareRound", "ResetValues", TTTVote.ResetTotems)
hook.Add("PlayerDeath", "TTTDestroyTotem", TTTVote.DestroyTotem)
hook.Add("Think", "TotemSuffer", TTTVote.TotemSuffer)
hook.Add("TTTBeginRound", "TTTTotemSync", TTTVote.TotemUpdate)
hook.Add("TTTBeginRound", "TTTTotemResetSuffer", TTTVote.ResetSuffer)
hook.Add("PlayerDisconnected", "TTTTotemSync", TTTVote.TotemUpdate)
