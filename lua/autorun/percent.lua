if SERVER then
  CreateConVar("ttt_startpercent"," 150",{FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Setze die Prozentzahl mit der jeder startet.")
  TTTPercent = TTTPercent or {}
  TTTPercent.percentbetters = TTTPercent.percentbetters or {}
  AddCSLuaFile()
  util.AddNetworkString("TTTPercentMenu")
  util.AddNetworkString("TTTPercentFailed")
  util.AddNetworkString("TTTPlacedPercent")
  util.AddNetworkString("TTTPercentMessage")
  util.AddNetworkString("TTTResetPercent")
  function TTTPercent.GetPercentMessage(sender, text, teamchat)
    local msg = string.lower(text)
    if string.sub(msg,1,8) == "!prozent" and GetRoundState() == ROUND_ACTIVE and sender:IsTerror() then
      if sender:GetNWInt("UsedPercentage",0) <= 0 then
        if sender:GetNWInt("PlayerPercentage") - sender:GetNWInt("UsedPercentage") >= 1 then
          net.Start("TTTPercentMenu")
          net.Send(sender)
          return false
        else
          net.Start("TTTPercentFailed")
          net.WriteBool(false)
          net.Send(sender)
          return false
        end
      else
        net.Start("TTTPercentFailed")
        net.WriteBool(true)
        net.Send(sender)
        return false
      end
    end
  end

  function TTTPercent.CalculatePercent(len, sender)
    local percent = net.ReadInt(12)
    local target = net.ReadEntity()
    TTTPercent.CalculatePercentage(sender,percent, false, target, sender)
    TTTPercent.CalculatePercentage(target,percent, true, target, sender)
    TTTPercent.SendPercentNotify(percent, sender, target)
  end

  function TTTPercent.SendPercentNotify(percent, sender, target)
    net.Start("TTTPercentMessage")
    net.WriteInt(percent,8)
    net.WriteEntity(sender)
    net.WriteEntity(target)
    net.Broadcast()
  end

  function TTTPercent.CalculatePercentage(ply,percent, selected, target, sender)
    if selected then
      ply:SetNWInt("PercentCounter", ply:GetNWInt("PercentCounter") + percent)
    else
      if TTTPercent.percentbetters[target:SteamID()] == nil then
        TTTPercent.percentbetters[target:SteamID()] = {}
      end
      table.insert(TTTPercent.percentbetters[target:SteamID()], ply)
      local totalpercent = percent + target:GetNWInt("PercentCounter")
      ply:SetNWInt("UsedPercentageontarget " .. target:SteamID(), ply:GetNWInt("UsedPercentageontarget " .. target:SteamID()) + percent )
      ply:SetNWInt("UsedPercentage", ply:GetNWInt("UsedPercentage") + percent )
      if totalpercent >= 100 then
        target:SetNWInt("PercentCounter", 100)
        ply:SetNWInt("UsedPercentageontarget " .. target:SteamID(), ply:GetNWInt("UsedPercentageontarget " .. target:SteamID()) - (totalpercent - 100) )
        ply:SetNWInt("UsedPercentage", ply:GetNWInt("UsedPercentage") - (totalpercent - 100) )
        for k,v in pairs(TTTPercent.percentbetters[target:SteamID()]) do
          TTTPercent.SetPercent(ply,v:GetNWInt("PlayerPercentage") - v:GetNWInt("UsedPercentageontarget " .. target:SteamID()))
          v:SetNWInt("UsedPercentageontarget " .. target:SteamID(), 0)
        end
        table.Empty(TTTPercent.percentbetters[target:SteamID()])
      end
    end
  end

  function TTTPercent.SetPercent(ply,percent)
    ply:SetNWInt("PlayerPercentage",percent)
    util.SetPData(ply:SteamID(),"percent_stored",percent)
  end

  function TTTPercent.ResetPercent(ply, reset)
    TTTPercent.SetPercent(ply, GetConVar("ttt_startpercent"):GetInt())
    ply:SetNWInt("PercentCounter",0)
    ply:SetNWInt("UsedPercentage", 0)
    for key,v in pairs(player.GetAll()) do
      ply:SetNWInt("UsedPercentageontarget" .. v:SteamID(), 0)
    end
    if reset then
      table.Empty(TTTPercent.percentbetters[ply:SteamID()])
    end
  end

  function TTTPercent.InitPercent(ply)
    if IsValid(ply) then
      local currentdate = os.date("%d/%m/%Y",os.time())
      if ply:GetPData("percent_stored_date") == nil then
        TTTPercent.SetDate(ply , currentdate)
        TTTPercent.SetPercent(ply, GetConVar("ttt_startpercent"):GetInt())
      end
      TTTPercent.InitPercentviaDate(ply, ply:GetPData("percent_stored_date"))
    end
  end

  function TTTPercent.InitPercentviaDate(ply, date)
    local currentdate = os.date("%d/%m/%Y",os.time())
    if date != currentdate then
      TTTPercent.SetPercent(ply, GetConVar("ttt_startpercent"):GetInt())
      TTTPercent.SetDate(ply , currentdate)
    else
      TTTPercent.SetPercent(ply,ply:GetPData("percent_stored"))
    end
  end

  function TTTPercent.SetDate(ply , date)
    ply:SetPData("percent_stored_date", date)
  end

  function TTTPercent.ResetPercentforEveryOne( ply, cmd, args )
    if (!IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
      for k,v in pairs(player.GetAll()) do
        TTTPercent.ResetPercent(v, false)
      end
      table.Empty(TTTPercent.percentbetters)
      net.Start("TTTResetPercent")
      net.WriteBool(true)
      net.Broadcast()
    end
  end

  function TTTPercent.ResetPercentforOnePlayer(ply, cmd, args)
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
        TTTPercent.ResetPercent(pl, true)
        net.Start("TTTResetPercent")
        net.WriteBool(false)
        net.Send(pl)
      end
    end
  end

  function TTTPercent.SavePercent(ply)
    if IsValid(ply) then
      util.SetPData(ply:SteamID(),"percent_stored", ply:GetNWInt("PlayerPercentage") )
      ply:SetNWInt("UsedPercentage", 0)
      ply:SetNWInt("PercentCounter", 0)
    end
  end

  function TTTPercent.SavePercentAll()
    for k, ply in pairs(player.GetAll()) do
      util.SetPData(ply:SteamID(),"percent_stored", ply:GetNWInt("PlayerPercentage") )
      ply:SetNWInt("UsedPercentage", 0)
      ply:SetNWInt("PercentCounter", 0)
    end
  end

  function TTTPercent.CalculatePercentRoundstart()
    for k,v in pairs(player.GetAll()) do
      v:SetNWInt("PercentCounter", 0)
      v:SetNWInt("UsedPercentage",0)
      for key,ply in pairs(player.GetAll()) do
        v:SetNWInt("UsedPercentageontarget" .. ply:SteamID(), 0)
      end
    end
  end

  local function AutoCompletePercent( cmd, stringargs )

    stringargs = string.Trim( stringargs ) -- Remove any spaces before or after.
    stringargs = string.lower( stringargs )

    local tbl = {}

    for k, v in pairs( player.GetAll() ) do
      local nick = v:Nick()
      if string.find( string.lower( nick ), stringargs ) then
        nick = "\"" .. nick .. "\"" -- We put quotes around it incase players have spaces in their names.
        nick = "ttt_resetpercentage " .. nick -- We also need to put the cmd before for it to work properly.

        table.insert( tbl, nick )
      end
    end

    return tbl
  end

  concommand.Add("ttt_resetallpercentages", TTTPercent.ResetPercentforEveryOne)
  concommand.Add("ttt_resetpercentage",TTTPercent.ResetPercentforOnePlayer, AutoCompletePercent)
  hook.Add("PlayerSay","TTTPercent", TTTPercent.GetPercentMessage)
  hook.Add("PlayerInitialSpawn", "InitialPercent", TTTPercent.InitPercent)
  net.Receive("TTTPlacedPercent", TTTPercent.CalculatePercent)
  hook.Add("PlayerDisconnected","TTTSavePercentage", TTTPercent.SavePercent)
  hook.Add("TTTPrepareRound", "ResetPercentages", TTTPercent.CalculatePercentRoundstart)
  hook.Add("TTTPrepareRound", "ResetPercentages", TTTPercent.CalculatePercentRoundstart)
  hook.Add("TTTEndRound", "ResetPercentages", TTTPercent.CalculatePercentRoundstart)
  hook.Add("ShutDown", "TTTSavePercentage", TTTPercent.SavePercentAll)
elseif CLIENT then
  surface.CreateFont("TTTPercentfont", {
      font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
      extended = false,
      size = 40,
      outline = true,
      antialias = false
    })
  net.Receive("TTTPercentMenu",function()
      local leftpercent = LocalPlayer():GetNWInt("PlayerPercentage") - LocalPlayer():GetNWInt("UsedPercentage")
      local frame = vgui.Create("DFrame")
      frame:SetSize( 500,360 )
      frame:Center()
      frame:SetSizable(false)
      frame:SetTitle( "" )
      frame:SetVisible(true)
      frame:SetDraggable( true )
      frame:MakePopup()
      frame:SetScreenLock(true)
      frame:SetDeleteOnClose(true)
      frame:ShowCloseButton(false)
      frame.Paint = function(s,w,h)
        draw.RoundedBox(5,0,0,w,h,Color(0,0,0))
        draw.RoundedBox(5,4,4,w-8,h-8,Color(70,70,70))
      end

      local DLabel = vgui.Create("DLabel",frame)
      DLabel:SetPos(frame:GetWide() / 2 - 25, frame:GetTall() / 1.5 - 50)
      DLabel:SetText( leftpercent .. "% Übrig." )
      DLabel:SetSize(100,100)
      DLabel:SetTextColor(COLOR_BLACK)

      local DLabel2 = vgui.Create("DLabel",frame)
      DLabel2:SetPos(frame:GetWide() / 2 - 100, frame:GetTall() / 2 - 225)
      DLabel2:SetText( "TTT Prozent" )
      DLabel2:SetSize(200,300)
      DLabel2:SetTextColor(Color(255,50,50))
      DLabel2:SetFont("TTTPercentfont")

      local DComboBox = vgui.Create( "DComboBox", frame )
      DComboBox:SetSize( 100, 20 )
      DComboBox:SetPos(100, frame:GetTall() / 2 - 10)
      DComboBox:SetValue( "Spieler" )
      for k,v in pairs(player.GetAll()) do
        if !v:IsBot() and v != LocalPlayer() then
          DComboBox:AddChoice(v:Nick(), v:SteamID())
        end
      end
      DComboBox.OnSelect = function( panel, index, value, data )
      end

      local Slider = vgui.Create("DNumSlider",frame)
      Slider:SetSize( 200, 100 )
      Slider:SetPos(frame:GetWide() - 250, frame:GetTall() / 2-50)
      Slider:SetText( "Prozent" )
      Slider:SetMin( 1 )
      Slider:SetMax( 34 )
      Slider:SetDecimals( 0 )
      Slider:SetValue(25)
      local DButton2 = vgui.Create("DButton",frame)
      DButton2:SetText( "Schließen" )
      DButton2:SetSize( 125, 30 )
      DButton2:SetPos(frame:GetWide() / 2 - 150, frame:GetTall() - 50)
      DButton2.DoClick = function()
        frame:Close()
      end

      local DButton = vgui.Create("DButton",frame)
      DButton:SetText( "Setzen" )
      DButton:SetSize( 125, 30 )
      DButton:SetPos(frame:GetWide() / 2 + 25, frame:GetTall() - 50)

      DButton.DoClick = function()

        local nick,steamid = DComboBox:GetSelected()
        local percent = math.Round(Slider:GetValue())

        if isstring(steamid) and steamid != "NULL" and steamid != "BOT" then
          local ply = player.GetBySteamID(steamid)
          if ply:GetNWInt("PercentCounter") < 100 then
            if percent <= leftpercent then
              net.Start("TTTPlacedPercent")
              net.WriteInt(percent,12)
              net.WriteEntity(ply)
              net.SendToServer()
            else
              net.Start("TTTPlacedPercent")
              net.WriteInt(leftpercent,12)
              net.WriteEntity(ply)
              net.SendToServer()
            end
          else
            chat.AddText("TTT Prozent: ", COLOR_RED, ply:Nick(), COLOR_WHITE, " ist schon frei zum Abschuss!")
            chat.PlaySound()
          end
        elseif nick == "" or !nick then
          chat.AddText("TTT Prozent: ", COLOR_WHITE, "Du hast keinen Spieler ausgewählt.")
          chat.PlaySound()
        end
        frame:Close()
      end

    end )

  net.Receive("TTTPercentMessage",function()
      local percent = net.ReadInt(8)
      local sender = net.ReadEntity()
      local target = net.ReadEntity()
      local totalpercent = target:GetNWInt("PercentCounter") + percent
      if totalpercent < 100 then
        chat.AddText("TTT Prozent: ", COLOR_GREEN, sender:Nick(), COLOR_WHITE, " hat " .. percent .. "% auf ", COLOR_RED, target:Nick(), COLOR_WHITE, " gesetzt. (" ,COLOR_BLUE, 100 - totalpercent .. "%", COLOR_WHITE, " bis zum freien Abschuss.)")
      else
        chat.AddText("TTT Prozent: ", COLOR_RED, target:Nick(), COLOR_WHITE, " ist nun frei zum Abschuss, da " , COLOR_GREEN, sender:Nick(), COLOR_WHITE, " die letzten Prozente gesetzt hat!")
        PrintCenteredKOSText(target:Nick() .. " ist nun frei zum Abschuss!",5,Color( 255, 50, 50 ))
      end
      chat.PlaySound()
    end)

  function PrintCenteredKOSText(txt,delay,color)
    if hook.GetTable()["TTTPercentKOS"] then
      hook.Remove("HUDPaint", "TTTPercentKOS")
      hook.Add("HUDPaint", "TTTPercentKOS", function() draw.SimpleText(txt,"TTTPercentfont",ScrW() / 2,ScrH() / 4 ,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end)
      timer.Adjust("RemoveTTTPercentKOS",delay , 1, function() hook.Remove("HUDPaint", "TTTPercentKOS") hook.Remove("TTTPrepareRound", "TTTRemovePercent") hook.Remove("TTTEndRound", "TTTRemovePercent") end)
    else
      hook.Add("HUDPaint", "TTTPercentKOS", function() draw.SimpleText(txt,"TTTPercentfont",ScrW() / 2,ScrH() / 4 ,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end)
      hook.Add("TTTPrepareRound", "TTTRemovePercent", function() hook.Remove("HUDPaint", "TTTPercentKOS") end)
      hook.Add("TTTEndRound", "TTTRemovePercent", function() hook.Remove("HUDPaint", "TTTPercentKOS") end)
      timer.Create("RemoveTTTPercentKOS",delay , 1, function() hook.Remove("HUDPaint", "TTTPercentKOS") hook.Remove("TTTPrepareRound", "TTTRemovePercent") hook.Remove("TTTEndRound", "TTTRemovePercent") end)
    end
  end

  net.Receive("TTTPercentFailed",function()
      local used = net.ReadBool()
      if used then
        chat.AddText("TTT Prozent: ", COLOR_WHITE, "Du hast diese Runde schon Prozente gesetzt!")
      else
        chat.AddText("TTT Prozent: ", COLOR_WHITE, "Du hast keine Prozente zum setzen!")
      end
      chat.PlaySound()
    end)
  net.Receive("TTTResetPercent",function()
      local all = net.ReadBool()
      if all then
        chat.AddText("TTT Prozent: ", COLOR_WHITE, "Alle Prozente wurden zurückgesetzt!")
      else
        chat.AddText("TTT Prozent: ", COLOR_WHITE, "Alle deine Prozente wurden von einem Admin zurückgesetzt!")
      end
      chat.PlaySound()
    end)
end
