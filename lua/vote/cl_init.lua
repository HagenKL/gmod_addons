if not TTTGF then
  TTTGF = {}

  -- function VoteEnabled() return GetGlobalBool("ttt_vote", false) end
  --
	-- function TotemEnabled() return GetGlobalBool("ttt_totem", false) end
  --
  -- net.Receive("SendGlobalBools", function()
  --   SetGlobalBool("ttt_vote", net.ReadBool())
  --   SetGlobalBool("ttt_vote", net.ReadBool())
  --
  -- end)
  include("vote/shared/vote_overrides_shd.lua")
  include("vote/shared/player.lua")
  include("vote/client/cl_halos.lua")
  include("vote/client/cl_messages.lua")
  include("vote/client/cl_menu.lua")
  include("vote/client/cl_changelog.lua")
  include("vote/client/cl_deathgrip.lua")
end
