TTTVote = TTTVote or {}
if SERVER then
  resource.AddWorkshop("828347015")
  local startvotes = CreateConVar("ttt_startvotes","5",{FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Setze die Vote mit der jeder startet.")
  TTTVote.votebetters = TTTVote.votebetters or {}
  AddCSLuaFile()
  util.AddNetworkString("TTTVoteMenu")
  util.AddNetworkString("TTTPlacedVote")
  util.AddNetworkString("TTTVoteMessage")
  util.AddNetworkString("TTTResetVote")
  util.AddNetworkString("TTTVoteRemoveHalos")
  util.AddNetworkString("TTTVoteAddHalos")
  util.AddNetworkString("TTTVoteRemoveHalos")
  util.AddNetworkString("TTTVoteBeacon")
  util.AddNetworkString("TTTVoteRemoveAllHalos")
  util.AddNetworkString("TTTNoBeacons")
  util.AddNetworkString("TTTVotePlaceBeacon")
  util.AddNetworkString("TTTVoteMenu")

  function TTTVote.GetVoteMessage(sender, text, teamchat)
    local msg = string.lower(text)
    if string.sub(msg,1,8) == "!prozent" and GetRoundState() == ROUND_ACTIVE and sender:IsTerror() then
      if sender:GetNWInt("UsedVotes",0) <= 0 and sender:GetNWInt("PlayerVotes") - sender:GetNWInt("UsedVotes") >= 1 then
        net.Start("TTTVoteMenu")
        net.Send(sender)
        return false
      end
    elseif string.sub(msg,1,11) == "!votebeacon" and GetRoundState() != ROUND_WAIT and sender:IsTerror() then
      TTTVote.PlaceBeacon(nil, sender)
      return false
    end
  end

  function TTTVote.ReceiveVotes(len, sender)
    local target = net.ReadEntity()
    target:SetNWInt("VoteCounter", target:GetNWInt("VoteCounter") + 1)
    TTTVote.CalculateVotes(sender, target, sender)
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
      TTTVote.AddHalos(target)
      local beacon = ply:GetNWEntity("VoteBeacon",NULL)
      if IsValid(beacon) then
      	beacon:AddHalos()
      end
      for k,v in pairs(TTTVote.votebetters[target:SteamID()]) do
          TTTVote.SetVotes(v,v:GetNWInt("PlayerVotes") - 1)
          ply:SetNWInt("UsedVotes", ply:GetNWInt("UsedVotes") - 1 )
          if target:IsRole(ROLE_INNOCENT) and (v:IsRole(ROLE_INNOCENT) or v:GetDetective()) then
 	        v:SetNWBool("TTTVotePunishment", true)
 	    end
      end
      table.Empty(TTTVote.votebetters[target:SteamID()])
    end
    TTTVote.SendVoteNotify(sender, target, target:GetNWInt("VoteCounter",0))
  end

  function TTTVote.SetVotes(ply, vote)
    ply:SetNWInt("PlayerVotes", vote)
    util.SetPData(ply:SteamID(),"vote_stored", vote)
  end

  function TTTVote.ResetVotes(ply, reset)
    TTTVote.SetVotes(ply, startvotes:GetInt())
    ply:SetNWInt("VoteCounter",0)
    ply:SetNWInt("UsedVotes", 0)
    ply:SetNWBool("TTTVotePunishment", false)
    if IsValid(ply:GetNWEntity("VoteBeacon")) then
    	ply:GetNWEntity("VoteBeacon"):TakeDamage(100000)
    end
    ply:SetNWEntity("VoteBeacon",NULL)
    ply:SetNWBool("PlacedBeacon", false)
    ply:SetNWBool("CanSpawnVoteBeacon", true)
    for key,v in pairs(player.GetAll()) do
      ply:SetNWInt("UsedVotesontarget " .. v:SteamID(), 0)
    end
    if reset and TTTVote.votebetters[ply:SteamID()] != nil then
      table.Empty(TTTVote.votebetters[ply:SteamID()])
    end
  end

  function TTTVote.InitVote(ply)
    if IsValid(ply) then
      local currentdate = os.date("%d/%m/%Y",os.time())
      if ply:GetPData("vote_stored_date") == nil then
        TTTVote.SetDate(ply , currentdate)
        TTTVote.SetVotes(ply, startvotes:GetInt())
      end
      TTTVote.InitVoteviaDate(ply, ply:GetPData("vote_stored_date"))
    end
  end

  function TTTVote.InitVoteviaDate(ply, date)
    local currentdate = os.date("%d/%m/%Y",os.time())
    if date != currentdate then
      TTTVote.SetVotes(ply, startvotes:GetInt())
      TTTVote.SetDate(ply , currentdate)
    else
      TTTVote.SetVotes(ply,ply:GetPData("vote_stored"))
    end
  end

  function TTTVote.SetDate(ply , date)
    ply:SetPData("vote_stored_date", date)
  end

  function TTTVote.ResetVoteforEveryOne( ply, cmd, args )
    if (!IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
      for k,v in pairs(player.GetAll()) do
        TTTVote.ResetVotes(v, false)
      end
      table.Empty(TTTVote.votebetters)
      net.Start("TTTResetVote")
      net.WriteBool(true)
      net.Broadcast()
      net.Start("TTTVoteRemoveAllHalos")
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
        TTTVote.ResetVotes(pl, true)
        net.Start("TTTResetVote")
        net.WriteBool(false)
        net.Send(pl)
      end
    end
  end

  function TTTVote.SaveVote(ply)
    if IsValid(ply) then
      util.SetPData(ply:SteamID(),"vote_stored", ply:GetNWInt("PlayerVotes") )
      ply:SetNWInt("UsedVotes", 0)
      ply:SetNWInt("VoteCounter", 0)
      ply:SetNWBool("TTTVotePunishment", false)
    end
  end

  function TTTVote.SaveVoteAll()
    for k, ply in pairs(player.GetAll()) do
      util.SetPData(ply:SteamID(),"vote_stored", ply:GetNWInt("PlayerVotes") )
      ply:SetNWInt("UsedVotes", 0)
      ply:SetNWInt("VoteCounter", 0)
      ply:SetNWBool("TTTVotePunishment", false)
    end
  end

  function TTTVote.CalculateVoteRoundstart()
    for k,v in pairs(player.GetAll()) do
      v:SetNWInt("VoteCounter", 0)
      v:SetNWInt("UsedVotes",0)
      for key,ply in pairs(player.GetAll()) do
        v:SetNWInt("UsedVotesontarget " .. ply:SteamID(), 0)
      end
    end
    net.Start("TTTVoteRemoveAllHalos")
    net.Broadcast()
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
      v.VoteBeaconSuffer = 0
    end
  end

  function TTTVote.RemoveHalos(ply)
    if ply:GetNWInt("VoteCounter",0) >= 3 then
      net.Start("TTTVoteRemoveHalos")
      net.WriteBool(true)
      net.WriteEntity(ply)
      net.Broadcast()
    end
  end

  function TTTVote.AddHalos(ply)
    if ply:GetNWInt("VoteCounter",0) >= 3 then
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

  function TTTVote.PlaceBeacon(len, sender)
    local ply = sender
    if !IsValid(ply) or !ply:IsTerror() then return end
    if !ply:GetNWBool("CanSpawnVoteBeacon", true) or IsValid(ply:GetNWEntity("VoteBeacon",NULL)) or ply:GetNWBool("PlacedBeacon") then
      net.Start("TTTVoteBeacon")
      net.WriteFloat(1)
      net.Send(ply)
      return
    end
    if !ply:OnGround() then
      net.Start("TTTVoteBeacon")
      net.WriteFloat(2)
      net.Send(ply)
      return
    end

    if ply:IsInWorld() then
      local votebeacon = ents.Create("ttt_votebeacon")
      if IsValid(votebeacon) then
        votebeacon:SetAngles(ply:GetAngles())

        votebeacon:SetPos(ply:GetPos())
        votebeacon:SetOwner(ply)
        votebeacon:Spawn()

        ply:SetNWBool("CanSpawnVoteBeacon",false)
        ply:SetNWBool("PlacedBeacon", true)
        ply:SetNWEntity("VoteBeacon",votebeacon)
        net.Start("TTTVoteBeacon")
        net.WriteFloat(3)
        net.Send(ply)
      end
    end
  end
  local NoBeaconsMessage = false
  function TTTVote.AdjustSpeed(ply)
    if GetRoundState() == ROUND_ACTIVE or GetRoundState() == ROUND_POST then
      local beacons
      for k,v in pairs(player.GetAll()) do
        if v:GetNWBool("CanSpawnVoteBeacon", false) or IsValid(v:GetNWEntity("VoteBeacon", NULL)) then
          beacons = true
          break
        else
          beacons = false
          continue
        end
      end
      local beacon = ply:GetNWEntity("VoteBeacon")
      if beacons then
        NoBeaconsMessage = false
        if IsValid(beacon) and beacon:GetPos():Distance(ply:GetPos()) > 2000 then
          return math.Round(math.Clamp(math.Remap(beacon:GetPos():Distance(ply:GetPos()),2000,5000,1,0),0.5,1),2)
        elseif IsValid(beacon) and beacon:GetPos():Distance(ply:GetPos()) < 1000 then
          return 1.25
        elseif IsValid(beacon) and beacon:GetPos():Distance(ply:GetPos()) > 1000 and beacon:GetPos():Distance(ply:GetPos()) < 2000 then
          return 1
        elseif !IsValid(beacon) then
          return 0.75
        end
      elseif !beacons then
        if !NoBeaconsMessage and #player.GetAll() >= 1 then
          NoBeaconsMessage = true
          net.Start("TTTNoBeacons")
          net.ReadBool(false)
          net.Broadcast()
        end
        return 1
      end
    else
      return 1
    end
  end

  hook.Add("Initialize", "TTTBeaconOverrideFunction", function ()
      local plymeta = FindMetaTable("Player")

      function plymeta:SetSpeed(slowed)
        local mul = TTTVote.AdjustSpeed(self) or 0.75
        if mul >= 1 and hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed) then
          mul = hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed)
        elseif mul < 1 and hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed) then
          mul = math.min(mul, hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed),100)
        end

        if slowed then
          self:SetWalkSpeed(120 * mul)
          self:SetRunSpeed(120 * mul)
          self:SetMaxSpeed(120 * mul)
        else
          self:SetWalkSpeed(220 * mul)
          self:SetRunSpeed(220 * mul)
          self:SetMaxSpeed(220 * mul)
        end
      end
    end )

  function TTTVote.VoteBeaconSuffer()
    if GetRoundState() == ROUND_ACTIVE then
      for k,v in pairs(player.GetAll()) do
        if v:IsTerror() and !v:GetNWBool("PlacedBeacon", true) and v:GetNWEntity("VoteBeacon", NULL) == NULL and isnumber(v.VoteBeaconSuffer) then
          if v.VoteBeaconSuffer == 0 then
            v.VoteBeaconSuffer = CurTime() + 30
            v.DamageNotified = false
          elseif v.VoteBeaconSuffer <= CurTime() then
            if !v.DamageNotified then
              net.Start("TTTVoteBeacon")
              net.WriteFloat(6)
              net.Send(v)
              v.DamageNotified = true
            end
            v:TakeDamage(1,v,v)
            v.VoteBeaconSuffer = CurTime() + 1
          end
        elseif v:IsTerror() and (v:GetNWEntity("VoteBeacon",NULL) or !isnumber(v.VoteBeaconSuffer)) then
          v.VoteBeaconSuffer = 0
          v.DamageNotified = false
        end
      end
    end
  end

  function TTTVote.ResetValues()
    for k,v in pairs(player.GetAll()) do
      v:SetNWBool("CanSpawnVoteBeacon", true)
      v:SetNWBool("PlacedBeacon", false)
      v:SetNWEntity("VoteBeacon", NULL)
      v:SetNWInt("VoteBeaconHealth",100)
      v.VoteBeaconSuffer = 0
      v.DamageNotified = false
    end
    NoBeaconsMessage = false
  end

  function TTTVote.DestroyBeacon(ply)
    if GetRoundState() == ROUND_ACTIVE then
      ply:SetNWBool("CanSpawnVoteBeacon", false)
    end
  end

  concommand.Add("ttt_resetallvotes", TTTVote.ResetVoteforEveryOne)
  concommand.Add("ttt_resetvotes",TTTVote.ResetVoteforOnePlayer, AutoCompleteVote)
  hook.Add("PlayerSay","TTTVote", TTTVote.GetVoteMessage)
  hook.Add("PlayerInitialSpawn", "InitialVote", TTTVote.InitVote)
  net.Receive("TTTPlacedVote", TTTVote.ReceiveVotes)
  net.Receive("TTTVotePlaceBeacon", TTTVote.PlaceBeacon)
  hook.Add("PlayerDisconnected","TTTSavevote", TTTVote.SaveVote)
  hook.Add("TTTPrepareRound", "ResetVotes", TTTVote.CalculateVoteRoundstart)
  hook.Add("TTTPrepareRound", "ResetValues", TTTVote.ResetValues)
  hook.Add("TTTBeginRound", "PunishtheInnocents", TTTVote.PunishtheInnocents)
  hook.Add("TTTEndRound", "ResetVotes", TTTVote.CalculateVoteRoundstart)
  hook.Add("ShutDown", "TTTSaveVotes", TTTVote.SaveVoteAll)
  hook.Add("PlayerDeath", "TTTVoteRemoveHalos", TTTVote.RemoveHalos)
  hook.Add("PlayerDeath", "TTTVoteDestroyBeacn", TTTVote.DestroyBeacon)
  hook.Add("PlayerSpawn", "TTTVoteAddHalos", TTTVote.AddHalos)
  hook.Add("Think", "VoteBeaconSuffer", TTTVote.VoteBeaconSuffer)

elseif CLIENT then

  TTTVote.halos = TTTVote.halos or {}

  surface.CreateFont("TTTVotefont", {
      font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
      extended = false,
      size = 40,
      outline = true,
      antialias = false
    })

  local votemenu = nil

  function TTTVote.OpenVoteMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(500,360)
    frame:Center()
    frame:SetSizable(false)
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(false)
    frame:SetMouseInputEnabled(true)
    frame:SetScreenLock(true)
    frame:SetDeleteOnClose(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame.Paint = function(s,w,h)
      draw.RoundedBox(5,0,0,w,h,Color(0,0,0))
      draw.RoundedBox(5,4,4,w-8,h-8,Color(70,70,70))
    end
    local DLabel = vgui.Create("DLabel",frame)
    DLabel:SetPos(frame:GetWide() / 2 - 75 / 2, frame:GetTall() / 2 + 100)
    DLabel:SetText(LocalPlayer():GetNWInt("PlayerVotes") - LocalPlayer():GetNWInt("UsedVotes") .. " Votes Übrig." )
    DLabel:SetSize(75,100)
    DLabel:SetTextColor(COLOR_WHITE)

    local DLabel2 = vgui.Create("DLabel",frame)
    DLabel2:SetPos(frame:GetWide() / 2 - 75, frame:GetTall() / 2 - 285)
    DLabel2:SetText( "TTT Vote" )
    DLabel2:SetSize(150,300)
    DLabel2:SetTextColor(Color(255,50,50))
    DLabel2:SetFont("TTTVotefont")

    local ListView = vgui.Create("DListView",frame)
    ListView:SetSize(400,225)
    ListView:SetPos(frame:GetWide() / 2 - 200, frame:GetTall() / 2 - 100 )
    ListView:AddColumn("Spieler")
    ListView:AddColumn("SteamID"):SetFixedWidth(10)
    ListView:SetMultiSelect(false)
    for k,v in pairs(player.GetAll()) do
      if !v:IsBot() and v != LocalPlayer() and !v:GetDetective() then
        ListView:AddLine(v:Nick(),v:SteamID())
      end
    end
    ListView.DoDoubleClick = function(List, lineID,line)
        if LocalPlayer():IsTerror() and GetRoundState() == ROUND_ACTIVE then
          local nick,steamid = line:GetColumnText(1), line:GetColumnText(2)
          if isstring(steamid) and steamid != "NULL" and steamid != "BOT" then
            local ply = player.GetBySteamID(steamid)
            if ply:GetNWInt("VoteCounter") < 3 then
              net.Start("TTTPlacedVote")
              net.WriteEntity(ply)
              net.SendToServer()
            else
              chat.AddText("TTT Vote: ", COLOR_RED, ply:Nick(), COLOR_WHITE, " ist schon frei zum Abschuss!")
              chat.PlaySound()
            end
          elseif nick == "" or !nick then
            chat.AddText("TTT Vote: ", COLOR_WHITE, "Du hast keinen Spieler ausgewählt.")
            chat.PlaySound()
          end
          frame:Close()
        else
          chat.AddText("TTT Vote: ", COLOR_WHITE, "Du kannst jetzt nicht mehr voten!")
          chat.PlaySound()
          frame:Close()
        end
    end
  votemenu = frame
  end

  net.Receive("TTTVoteMessage",function()
      local sender = net.ReadEntity()
      local target = net.ReadEntity()
      local totalvotes = net.ReadInt(16)
      if totalvotes < 3 then
        chat.AddText("TTT Vote: ", COLOR_GREEN, sender:Nick(), COLOR_WHITE, " votet auf den verdächtigen ", COLOR_RED, target:Nick(), COLOR_WHITE, "! (" .. totalvotes .. "/3)")
      else
        chat.AddText("TTT Vote: ", COLOR_RED, target:Nick(), COLOR_WHITE, " ist nun frei zum Abschuss, da " , COLOR_GREEN, sender:Nick(), COLOR_WHITE, " ihm die letzte Stimme gegeben hat!")
        TTTVote.PrintCenteredKOSText(target:Nick() .. " ist nun frei zum Abschuss!",5,Color( 255, 50, 50 ))
      end
      chat.PlaySound()
    end)

  function TTTVote.PrintCenteredKOSText(txt,delay,color)
    if hook.GetTable()["TTTVoteKOS"] then
      hook.Remove("HUDPaint", "TTTVoteKOS")
      hook.Add("HUDPaint", "TTTVoteKOS", function() draw.SimpleText(txt,"TTTVotefont",ScrW() / 2,ScrH() / 4 ,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end)
      timer.Adjust("RemoveTTTVoteKOS",delay , 1, function() hook.Remove("HUDPaint", "TTTVoteKOS") hook.Remove("TTTPrepareRound", "TTTRemoveVote") hook.Remove("TTTEndRound", "TTTRemoveVote") end)
    else
      hook.Add("HUDPaint", "TTTVoteKOS", function() draw.SimpleText(txt,"TTTVotefont",ScrW() / 2,ScrH() / 4 ,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end)
      hook.Add("TTTPrepareRound", "TTTRemoveVote", function() hook.Remove("HUDPaint", "TTTVoteKOS") end)
      hook.Add("TTTEndRound", "TTTRemoveVote", function() hook.Remove("HUDPaint", "TTTVoteKOS") end)
      timer.Create("RemoveTTTVoteKOS",delay , 1, function() hook.Remove("HUDPaint", "TTTVoteKOS") hook.Remove("TTTPrepareRound", "TTTRemoveVote") hook.Remove("TTTEndRound", "TTTRemoveVote") end)
    end
  end

  net.Receive("TTTResetVote",function()
      local all = net.ReadBool()
      if all then
        chat.AddText("TTT Vote: ", COLOR_WHITE, "Alle Votes wurden zurückgesetzt!")
        table.Empty(TTTVote.halos)
      else
        chat.AddText("TTT Vote: ", COLOR_WHITE, "Alle deine Votes wurden von einem Admin zurückgesetzt!")
      end
      chat.PlaySound()
    end)
  function TTTVote.VoteMakeCounter(pnl)
    pnl:AddColumn("Votes", function(ply)
        if ply:GetNWInt("VoteCounter",0) < 3 then
          return ply:GetNWInt("VoteCounter",0)
        elseif ply:GetNWInt("VoteCounter",0) >= 3 then
          return 3
        end
      end)
     pnl:AddColumn("Totem", function(ply)
        if ply:GetNWEntity("VoteBeacon",NULL) != NULL then
          return "Ja"
        else
          return "Nein"
        end
      end)
  end

  function TTTVote.MakeVoteScoreBoardColor(ply)
    if ply:GetNWInt("VoteCounter",0) >= 3 then
      return Color(0,120,0)
    end
  end

  function TTTVote.PrepareRoundVote()
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

  function TTTVote.BeaconMessage()
    local bool = net.ReadFloat()
    if bool == 1 then
      chat.AddText("TTT Totem: ", COLOR_WHITE, "Du hast schon ein Totem plaziert!")
    elseif bool == 2 then
      chat.AddText("TTT Totem: ", COLOR_WHITE, "Du musst beim Plazieren deines Totems auf dem Boden stehen!")
    elseif bool == 3 then
      chat.AddText("TTT Totem: ", COLOR_WHITE, "Dein Totem wurde erfolgreich plaziert!")
    elseif bool == 4 then
      chat.AddText("TTT Totem: ", COLOR_WHITE, "Du hast dein Totem erfolgreich aufgehoben!")
    elseif bool == 5 then
      local owner = net.ReadEntity()
      local attacker = net.ReadEntity()
      if IsValid(attacker) and IsValid(owner) then
        chat.AddText("TTT Totem: ", COLOR_WHITE, "Das Totem von " ,COLOR_GREEN, owner:Nick(), COLOR_WHITE, " wurde von ", COLOR_RED, attacker:Nick(), COLOR_WHITE, " zerstört!")
      end
    elseif bool == 6 then
      chat.AddText("TTT Totem: ", COLOR_WHITE, "Du verlierst nun leben weil du kein Totem plaziert hast!")
    end
    chat.PlaySound()
  end

  function TTTVote.NoBeacons()
    chat.AddText("TTT Totem: ", COLOR_WHITE, "Alle Totems wurden zerstört, ihr seid nun wieder normal schnell!")
    chat.PlaySound()
  end

  function TTTVote.LookUpVoteMenu(ply, cmd, args, argStr)
  	if votemenu and IsValid(votemenu) then votemenu:Close() return end
    if LocalPlayer() == ply and GetRoundState() == ROUND_ACTIVE and LocalPlayer():IsTerror() then
      if ply:GetNWInt("PlayerVotes") - ply:GetNWInt("UsedVotes") >= 1 then
        if ply:GetNWInt("UsedVotes",0) <= 0 then
          TTTVote.OpenVoteMenu()
        else
         chat.AddText("TTT Vote: ", COLOR_WHITE, "Du hast diese Runde schon gevotet!")
         chat.PlaySound()
        end
      else
        chat.AddText("TTT Vote: ", COLOR_WHITE, "Du hast keine Votes mehr!")
        chat.PlaySound()
      end
    else
      chat.AddText("TTT Vote: ", COLOR_WHITE, "Du bist nicht mehr am leben oder die Runde ist nicht aktiv!")
      chat.PlaySound()
    end
  end

  function TTTVote.LookUpVoteMenuFallback(len)
  	if votemenu and IsValid(votemenu) then votemenu:Close() return end
    if GetRoundState() == ROUND_ACTIVE and LocalPlayer():IsTerror() then
      if LocalPlayer():GetNWInt("PlayerVotes") - LocalPlayer():GetNWInt("UsedVotes") >= 1 then
        if LocalPlayer():GetNWInt("UsedVotes",0) <= 0 then
          TTTVote.OpenVoteMenu()
        else
         chat.AddText("TTT Vote: ", COLOR_WHITE, "Du hast diese Runde schon gevotet!")
         chat.PlaySound()
        end
      else
        chat.AddText("TTT Vote: ", COLOR_WHITE, "Du hast keine Votes mehr!")
        chat.PlaySound()
      end
    else
      chat.AddText("TTT Vote: ", COLOR_WHITE, "Du bist nicht mehr am leben oder die Runde ist nicht aktiv!")
      chat.PlaySound()
    end
  end

  /*function TTTVote.CloseVoteMenu(ply, cmd, args, argStr)
    if votemenu and IsValid(votemenu) then votemenu:Close() end
  end*/

  function TTTVote.LookUpBeacon(ply, cmd, args, argStr)
    if GetRoundState() != ROUND_WAIT and LocalPlayer() == ply and LocalPlayer():IsTerror() then
      net.Start("TTTVotePlaceBeacon")
      net.SendToServer()
    end
  end

  function TTTVote.ApplyBeaconHalos(ent)
    if ent:GetClass() == "ttt_votebeacon" and ent:GetOwner():GetNWInt("VoteCounter",0) >= 3 then
      table.insert(TTTVote.halos,ent)
    end
  end

  --concommand.Add("+votemenu", TTTVote.LookUpVoteMenu,nil,"Opens the vote menu", { FCVAR_DONTRECORD })
  --concommand.Add("-votemenu", TTTVote.CloseVoteMenu,nil,"Closes the vote menu", { FCVAR_DONTRECORD })
  concommand.Add("votemenu", TTTVote.LookUpVoteMenu,nil,"Opens / Closes the vote menu", { FCVAR_DONTRECORD })
  concommand.Add("placebeacon", TTTVote.LookUpBeacon,nil,"Places a Beacon", { FCVAR_DONTRECORD })
  net.Receive("TTTNoBeacons", TTTVote.NoBeacons)
  net.Receive("TTTVoteBeacon",TTTVote.BeaconMessage)
  net.Receive("TTTVoteRemoveAllHalos", TTTVote.RemoveAllHalos)
  net.Receive("TTTVoteRemoveHalos",TTTVote.ClientRemoveHalos)
  net.Receive("TTTVoteAddHalos",TTTVote.ClientAddHalos)
  net.Receive("TTTVoteMenu",TTTVote.LookUpVoteMenuFallback)
  hook.Add("OnEntityCreated", "TTTVoteBeaconHalos", TTTVote.ApplyBeaconHalos)
  hook.Add("TTTPrepareRound","TTTVoteReset", TTTVote.PrepareRoundVote)
  hook.Add("PreDrawHalos","TTTVoteHalos", TTTVote.DrawVoteHalos)
  hook.Add("TTTScoreboardRowColorForPlayer", "TTTVoteColorScoreboard", TTTVote.MakeVoteScoreBoardColor)
  hook.Add("TTTScoreboardColumns", "TTTVoteCounteronScoreboard", TTTVote.VoteMakeCounter)
end
