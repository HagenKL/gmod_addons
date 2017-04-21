surface.CreateFont("TTTVotefont", {
    font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
    extended = false,
    size = 40,
    outline = true,
    antialias = false
  })

net.Receive("TTTVoteMessage",function()
    local sender = net.ReadEntity()
    local target = net.ReadEntity()
    local totalvotes = net.ReadInt(16)
    local hastotem = net.ReadBool()
    if totalvotes < 3 then
      chat.AddText("TTT Vote: ", COLOR_GREEN, sender:Nick(), COLOR_WHITE, " votet auf den verdächtigen ", COLOR_RED, target:Nick(), COLOR_WHITE, "! (" .. totalvotes .. "/3)")
    else
      if hastotem then
        chat.AddText("TTT Vote: ", COLOR_RED, target:Nick(), COLOR_WHITE, " ist nun frei zum Abschuss, da " , COLOR_GREEN, sender:Nick(), COLOR_WHITE, " ihm die letzte Stimme gegeben hat! Bevor er markiert wird müsst ihr sein Totem finden und zerstören!")
      else
        chat.AddText("TTT Vote: ", COLOR_RED, target:Nick(), COLOR_WHITE, " ist nun frei zum Abschuss, da " , COLOR_GREEN, sender:Nick(), COLOR_WHITE, " ihm die letzte Stimme gegeben hat!")
      end
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

function TTTVote.TotemMessage()
  local bool = net.ReadInt(8)
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
      chat.AddText("TTT Totem: ", COLOR_WHITE, "Ein Totem wurde zerstört!")
    end
  elseif bool == 6 then
    chat.AddText("TTT Totem: ", COLOR_WHITE, "Du verlierst nun leben weil du kein Totem plaziert hast!")
  elseif bool == 7 then
    local ply = net.ReadEntity()
    chat.AddText("TTT Vote: ", COLOR_WHITE, "Das Totem von ",COLOR_GREEN, ply:Nick(), COLOR_WHITE," wurde zerstört, er ist nun für alle durch die Wand sichtbar!")
  elseif bool == 8 then
    chat.AddText("TTT Totem: ", COLOR_WHITE, "Alle Totems wurden zerstört!")
  elseif bool == 9 then
    chat.AddText("TTT Totem: ", COLOR_WHITE, "Du hast dein Totem schon 2 mal aufgehoben!")
  end
  chat.PlaySound()
end

net.Receive("TTTTotem",TTTVote.TotemMessage)
net.Receive("TTTVoteMenu",TTTVote.LookUpVoteMenu)
net.Receive("TTTVoteCurse",TTTVote.Curse)
