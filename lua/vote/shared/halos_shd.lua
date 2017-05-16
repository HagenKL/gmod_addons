if SERVER then
  function TTTVote.RemoveHalos(ply)
    if ply:GetNWInt("VoteCounter",0) >= 3 then
      net.Start("TTTVoteRemoveHalos")
      net.WriteBool(true)
      net.WriteEntity(ply)
      net.Broadcast()
    end
  end

  function TTTVote.AddHalos(ply)
    if ply:GetNWInt("VoteCounter",0) >= 3 and ply:IsTerror() then
      net.Start("TTTVoteAddHalos")
      net.WriteBool(true)
      net.WriteEntity(ply)
      net.Broadcast()
    else
      net.Start("TTTVoteRemoveHalos")
      net.WriteBool(true)
      net.WriteEntity(ply)
      net.Broadcast()
    end
  end
  hook.Add("PlayerDeath", "TTTVoteRemoveHalos", TTTVote.RemoveHalos)
  hook.Add("PlayerSpawn", "TTTVoteAddHalos", TTTVote.AddHalos)
elseif CLIENT then
  TTTVote.halos = TTTVote.halos or {}
  function TTTVote.HalosReset()
    table.Empty(TTTVote.halos)
  end

  function TTTVote.DrawVoteHalos()
    halo.Add(TTTVote.halos,Color(0,255,0),1,1,2,true,true)
  end

  function TTTVote.ClientRemoveHalos()
    local isplayer = net.ReadBool()
    local ent = net.ReadEntity()
    if isplayer then
      table.RemoveByValue(TTTVote.halos,ent)
    elseif !isplayer and IsValid(ent) then
      table.RemoveByValue(TTTVote.halos,ent)
    end
  end

  function TTTVote.ClientAddHalos()
    local isplayer = net.ReadBool()
    local ent = net.ReadEntity()
    if isplayer then
      table.insert(TTTVote.halos,ent)
    elseif !isplayer and IsValid(ent) then
      table.insert(TTTVote.halos,ent)
    end
  end

  function TTTVote.RemoveAllHalos()
    table.Empty(TTTVote.halos)
  end

  function TTTVote.ApplyTotemHalos(ent)
    if ent:GetClass() == "ttt_totem" and ent:GetOwner():GetNWInt("VoteCounter",0) >= 3 then
      table.insert(TTTVote.halos,ent)
    end
  end

  net.Receive("TTTVoteRemoveAllHalos", TTTVote.RemoveAllHalos)
  net.Receive("TTTVoteRemoveHalos",TTTVote.ClientRemoveHalos)
  net.Receive("TTTVoteAddHalos",TTTVote.ClientAddHalos)
  hook.Add("OnEntityCreated", "TTTVoteTotemHalos", TTTVote.ApplyTotemHalos)
  hook.Add("TTTPrepareRound","TTTVoteReset", TTTVote.HalosReset)
  hook.Add("PreDrawHalos","TTTVoteHalos", TTTVote.DrawVoteHalos)
end
