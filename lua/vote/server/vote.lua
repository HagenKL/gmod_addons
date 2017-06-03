function TTTVote.ReceiveVotes(len, sender)
  local target = net.ReadEntity()
  if target:GetNWInt("VoteCounter") < 3 then
	  target:SetNWInt("VoteCounter", target:GetNWInt("VoteCounter") + 1)
	  TTTVote.CalculateVotes(sender, target, sender)
  else
  	net.Start("TTTVoteFailure")
  	net.WriteEntity(target)
  	net.Send(sender)
  end
end

function TTTVote.SendVoteNotify(sender, target, totalvotes)
  net.Start("TTTVoteMessage")
  net.WriteEntity(sender)
  net.WriteEntity(target)
  net.WriteInt(totalvotes,16)
  net.Broadcast()
end

function TTTVote.CalculateVotes(ply, target, sender)
  TTTVote.votebetters[target:SteamID()] = TTTVote.votebetters[target:SteamID()] or {}
  table.insert(TTTVote.votebetters[target:SteamID()], ply)
  ply:SetNWInt("UsedVotes", ply:GetNWInt("UsedVotes") + 1 )
  if target:GetNWInt("VoteCounter",0) >= 3 then
    target:SetNWInt("VoteCounter", 3)
    for k,v in pairs(TTTVote.votebetters[target:SteamID()]) do
      v:UsedVote()
      if target:GetGood() and v:GetGood() then
        v:SetNWBool("TTTVotePunishment", true)
      end
    end
    table.Empty(TTTVote.votebetters[target:SteamID()])
  end
  TTTVote.SendVoteNotify(sender, target, target:GetNWInt("VoteCounter",0))
end

function TTTVote.ResetVotes(ply)
  ply.totemuses = 0
  ply:ResetVotes()
  ply:SetNWInt("VoteCounter",0)
  ply:SetNWInt("UsedVotes", 0)
  ply:SetNWBool("TTTVotePunishment", false)
  TTTVote.AnyTotems = true
  local totem = ply:GetNWEntity("Totem")
  if IsValid(totem) then
    totem:FakeDestroy()
  end

  ply:SetNWEntity("Totem",NULL)
  ply:SetNWBool("PlacedTotem", false)
  ply:SetNWBool("CanSpawnTotem", true)
  ply.DamageNotified = false
  ply.TotemSuffer = 0

  for key,v in pairs(player.GetAll()) do
    ply:SetNWInt("UsedVotesontarget " .. v:SteamID(), 0)
  end
  if SERVER and TTTVote.votebetters[ply:SteamID()] and istable(TTTVote.votebetters[ply:SteamID()]) then
    table.Empty(TTTVote.votebetters[ply:SteamID()])
  end
end

local function OpenChangelogMenu(ply)
  net.Start("VoteChangelog")
  net.WriteString(file.Read("vote/changelog.lua", "LUA"))
  net.Send(ply)
end

function TTTVote.InitVote(ply)
  if IsValid(ply) then
    local currentdate = os.date("%d/%m/%Y",os.time())
    if ply:GetPData("vote_stored_date") == nil then
      TTTVote.SetDate(ply , currentdate)
      ply:ResetVotes()
      OpenChangelogMenu(ply)
    end
    TTTVote.InitVoteviaDate(ply, ply:GetPData("vote_stored_date"))
  end
end

function TTTVote.InitVoteviaDate(ply, date)
  local currentdate = os.date("%d/%m/%Y",os.time())
  if date != currentdate then
    TTTVote.SetDate(ply , currentdate)
    ply:ResetVotes()
    OpenChangelogMenu(ply)
  else
    ply:SetVotes(ply:GetPData("vote_stored"))
  end
end

function TTTVote.SetDate(ply , date)
  ply:SetPData("vote_stored_date", date)
end

function TTTVote.ResetVoteforEveryOne( ply, cmd, args )
  if (!IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
    for k,v in pairs(player.GetAll()) do
      TTTVote.ResetVotes(v)
    end
    net.Start("TTTResetVote")
    net.WriteBool(true)
    net.Broadcast()
  end
end

function TTTVote.ResetVoteforOnePlayer(ply, cmd, args)
  if (!IsValid(ply) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0)) and args[1] != nil then
    local _match = NULL;
    for k, v in pairs( player.GetAll( ) ) do
      local _find = string.find( string.lower( v:Nick( ) ), string.lower( args[ 1 ] ) ); -- Returns nil if pattern not found, otherwise it returns index or so: [url]http://maurits.tv/data/garrysmod/wiki/wiki.garrysmod.com/index15fa.html[/url]
      if ( !_find ) then
        continue;
      else
        _match = v;
        break;
      end
    end
    local pl = _match
    if IsValid(pl) then
      TTTVote.ResetVotes(pl)
      net.Start("TTTResetVote")
      net.WriteBool(false)
      net.Send(pl)
    end
  end
end

function TTTVote.SaveVote(ply)
  if IsValid(ply) then
    util.SetPData(ply:SteamID(),"vote_stored", ply:GetVotes() )
    ply:SetNWInt("UsedVotes", 0)
    ply:SetNWInt("VoteCounter", 0)
    ply:SetNWBool("TTTVotePunishment", false)
  end
end

function TTTVote.SaveVoteAll()
  for k, ply in pairs(player.GetAll()) do
    util.SetPData(ply:SteamID(),"vote_stored", ply:GetVotes() )
    ply:SetNWInt("UsedVotes", 0)
    ply:SetNWInt("VoteCounter", 0)
    ply:SetNWBool("TTTVotePunishment", false)
  end
end

function TTTVote.CalculateVoteRoundstart()
  for k,v in pairs(player.GetAll()) do
    v:SetNWInt("VoteCounter", 0)
    v:SetNWInt("UsedVotes",0)
    TTTVote.AnyTotems = true
    for key,ply in pairs(player.GetAll()) do
      v:SetNWInt("UsedVotesontarget " .. ply:SteamID(), 0)
    end
  end
end

local function AutoCompleteVote( cmd, stringargs )

  stringargs = string.Trim( stringargs ) -- Remove any spaces before or after.
  stringargs = string.lower( stringargs )

  local tbl = {}

  for k, v in pairs( player.GetAll() ) do
    local nick = v:Nick()
    if string.find( string.lower( nick ), stringargs ) then
      nick = "\"" .. nick .. "\"" -- We put quotes around it incase players have spaces in their names.
      nick = "ttt_resetvotes " .. nick -- We also need to put the cmd before for it to work properly.

      table.insert( tbl, nick )
    end
  end

  return tbl
end

function TTTVote.PunishtheInnocents()
  for k,v in pairs(player.GetAll()) do
    if v:IsTerror() and v:GetNWBool("TTTVotePunishment",false) then
      v:SetHealth(v:GetMaxHealth() - 10)
      v:SetNWBool("TTTVotePunishment",false)
    end
  end
end

function TTTVote.IsEven(number)
  return number % 2 == 0
end

concommand.Add("ttt_votechangelog", OpenChangelogMenu)
concommand.Add("ttt_resetallvotes", TTTVote.ResetVoteforEveryOne)
concommand.Add("ttt_resetvotes",TTTVote.ResetVoteforOnePlayer, AutoCompleteVote)
hook.Add("PlayerInitialSpawn", "InitialVote", TTTVote.InitVote)
net.Receive("TTTPlacedVote", TTTVote.ReceiveVotes)
hook.Add("PlayerDisconnected","TTTSavevote", TTTVote.SaveVote)
hook.Add("TTTPrepareRound", "ResetVotes", TTTVote.CalculateVoteRoundstart)
hook.Add("TTTBeginRound", "PunishtheInnocents", TTTVote.PunishtheInnocents)
hook.Add("TTTEndRound", "ResetVotes", TTTVote.CalculateVoteRoundstart)
hook.Add("ShutDown", "TTTSaveVotes", TTTVote.SaveVoteAll)
