if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddWorkshop("606792331")
end
SWEP.HoldType = "knife"

if CLIENT then

  SWEP.PrintName = "Advanced Disguiser"
  SWEP.Slot = 8

  SWEP.ViewModelFlip = false

  SWEP.EquipMenuData = {
    type = "Weapon",
    desc = "Steal player's identity."
  };

  SWEP.Icon = "VGUI/ttt/icon_adv_disguiser"
end

SWEP.Base = "weapon_tttbase"

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54
SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"

SWEP.DrawCrosshair = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 2
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Primary.Delay = 2
SWEP.Kind = WEAPON_ROLE
SWEP.AutoSpawnable = false
SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy
SWEP.LimitedStock = true -- only buyable once

SWEP.IsSilent = true

-- Pull out faster than standard guns

if CLIENT then
  local function AdvDisguiserInit()
    local key_params = {usekey = Key("+use", "USE"), walkkey = Key("+walk", "WALK")}
    local ClassHint = {
      prop_ragdoll = {
        name= "corpse",
        hint= "corpse_hint",

        fmt = function(ent, txt) return LANG.GetParamTranslation(txt, key_params) end
      }
    };
    local function DrawPropSpecLabels(client)
      if (not client:IsSpec()) and (GetRoundState() != ROUND_POST) then return end
      surface.SetFont("TabLarge")
      local tgt = nil
      local scrpos = nil
      local text = nil
      local w = 0
      for _, ply in pairs(player.GetAll()) do
        if ply:IsSpec() then
          surface.SetTextColor(220,200,0,120)

          tgt = ply:GetObserverTarget()

          if IsValid(tgt) and tgt:GetNWEntity("spec_owner", nil) == ply then

            scrpos = tgt:GetPos():ToScreen()
          else
            scrpos = nil
          end
        else
          local _, healthcolor = util.HealthToString(ply:Health())
          surface.SetTextColor(clr(healthcolor))

          scrpos = ply:EyePos()
          scrpos.z = scrpos.z + 20

          scrpos = scrpos:ToScreen()
        end
        if scrpos and (not IsOffScreen(scrpos)) then
          text = ply:Nick()
          w, _ = surface.GetTextSize(text)

          surface.SetTextPos(scrpos.x - w / 2, scrpos.y)
          surface.DrawText(text)
        end
      end
    end

    surface.CreateFont("TargetIDSmall2", {font = "TargetID",
        size = 16,
        weight = 1000})
    local minimalist = CreateConVar("ttt_minimal_targetid", "0", FCVAR_ARCHIVE)
    local magnifier_mat = Material("icon16/magnifier.png")
    local ring_tex = surface.GetTextureID("effects/select_ring")
    local rag_color = Color(200,200,200,255)
    local GetLang = LANG.GetUnsafeLanguageTable

    function GAMEMODE:HUDDrawTargetID()
      local client = LocalPlayer()
      local L = GetLang()

      DrawPropSpecLabels(client)

      local trace = client:GetEyeTrace(MASK_SHOT)
      local ent = trace.Entity
      if (not IsValid(ent)) or ent.NoTarget then return end

      -- some bools for caching what kind of ent we are looking at
      local target_traitor = false
      local target_detective = false
      local target_corpse = false
      local target_advdisguised = false

      local text = nil
      local color = COLOR_WHITE

      -- if a vehicle, we identify the driver instead
      if IsValid(ent:GetNWEntity("ttt_driver", nil)) then
        ent = ent:GetNWEntity("ttt_driver", nil)
        if ent == client then return end
      end

      local cls = ent:GetClass()
      local minimal = minimalist:GetBool()
      local hint = (not minimal) and (ent.TargetIDHint or ClassHint[cls])

      if ent:IsPlayer() then
        target_advdisguised = ent:GetNWBool("AdvDisguiseInDisguise")
        if ent:GetNWBool("disguised", false) then
          client.last_id = nil

          if client:IsTraitor() or client:IsSpec() then
            text = ent:Nick() .. L.target_disg
          else
            -- Do not show anything
            return
          end

          color = COLOR_RED
        elseif target_advdisguised then
          client.last_id = nil

          if (client:IsTraitor() and ent:IsTraitor()) or client:IsSpec() then
            text = ent:Nick() .. " (Disguised as " .. ent:GetNWString("AdvDisguiseName") .. ")"
            color = COLOR_RED
          else

            text = ent:GetNWString("AdvDisguiseName")
            client.last_id = ent:GetNWEntity("AdvDisguiseEnt",nil)
          end

        else

          text = ent:Nick()
          client.last_id = ent
        end

        -- in minimalist targetID, colour nick with health level
        if minimal then
          _, color = util.HealthToString(ent:Health())
        end

        if client:IsTraitor() and GAMEMODE.round_state == ROUND_ACTIVE then
          target_traitor = ent:IsTraitor()
        end

        target_detective = ent:GetNWBool("AdvDisguiseInDisguise") and ent:GetNWBool("AdvDisguiseIsDetective") or ent:IsDetective()

      elseif cls == "prop_ragdoll" then
        -- only show this if the ragdoll has a nick, else it could be a mattress
        if CORPSE.GetPlayerNick(ent, false) == false then return end

        target_corpse = true

        if CORPSE.GetFound(ent, false) or not DetectiveMode() then
          text = CORPSE.GetPlayerNick(ent, "A Terrorist")
        else
          text = L.target_unid
          color = COLOR_YELLOW
        end
      elseif not hint then
        -- Not something to ID and not something to hint about
        return
      end

      local x_orig = ScrW() / 2.0
      local x = x_orig
      local y = ScrH() / 2.0

      local w, h = 0,0 -- text width/height, reused several times

      if target_traitor or target_detective then
        surface.SetTexture(ring_tex)

        if target_traitor then
          surface.SetDrawColor(255, 0, 0, 200)
        else
          surface.SetDrawColor(0, 0, 255, 220)
        end
        surface.DrawTexturedRect(x-32, y-32, 64, 64)
      end

      y = y + 30
      local font = "TargetID"
      surface.SetFont( font )

      -- Draw main title, ie. nickname
      if text then
        w, h = surface.GetTextSize( text )

        x = x - w / 2

        draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
        draw.SimpleText( text, font, x, y, color )

        -- for ragdolls searched by detectives, add icon
        if ent.search_result and client:IsDetective() then
          -- if I am detective and I know a search result for this corpse, then I
          -- have searched it or another detective has
          surface.SetMaterial(magnifier_mat)
          surface.SetDrawColor(200, 200, 255, 255)
          surface.DrawTexturedRect(x + w + 5, y, 16, 16)
        end

        y = y + h + 4
      end

      -- Minimalist target ID only draws a health-coloured nickname, no hints, no
      -- karma, no tag
      if minimal then return end

      -- Draw subtitle: health or type
      local clr = rag_color
      if ent:IsPlayer() then
        text, clr = util.HealthToString(ent:Health())

        -- HealthToString returns a string id, need to look it up
        text = L[text]
      elseif hint then
        text = LANG.GetRawTranslation(hint.name) or hint.name
      else
        return
      end
      font = "TargetIDSmall2"

      surface.SetFont( font )
      w, h = surface.GetTextSize( text )
      x = x_orig - w / 2

      draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
      draw.SimpleText( text, font, x, y, clr )

      font = "TargetIDSmall"
      surface.SetFont( font )

      -- Draw second subtitle: karma
      if ent:IsPlayer() and KARMA.IsEnabled() then
        text, clr = util.KarmaToString(ent:GetNWBool("AdvDisguiseInDisguise") and ent:GetNWInt("AdvDisguiseKarma") or ent:GetBaseKarma())

        text = L[text]

        w, h = surface.GetTextSize( text )
        y = y + h + 5
        x = x_orig - w / 2

        draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
        draw.SimpleText( text, font, x, y, clr )
      end

      -- Draw key hint
      if hint and hint.hint then
        if not hint.fmt then
          text = LANG.GetRawTranslation(hint.hint) or hint.hint
        else
          text = hint.fmt(ent, hint.hint)
        end

        w, h = surface.GetTextSize(text)
        x = x_orig - w / 2
        y = y + h + 5
        draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
        draw.SimpleText( text, font, x, y, COLOR_LGRAY )
      end

      text = nil

      if target_traitor then
        text = L.target_traitor
        clr = COLOR_RED
      elseif target_detective then
        text = L.target_detective
        clr = COLOR_BLUE
      elseif not ent:GetNWBool("AdvDisguiseInDisguise") and ent.sb_tag and ent.sb_tag.txt != nil then
        text = L[ ent.sb_tag.txt ]
        clr = ent.sb_tag.color
      elseif ent:GetNWBool("AdvDisguiseInDisguise") and IsValid(ent:GetNWEntity("AdvDisguiseEnt",nil)) and ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag and ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag.txt != nil then
        text = L[ ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag.txt ]
        clr = ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag.color
      elseif target_corpse and client:IsActiveTraitor() and CORPSE.GetCredits(ent, 0) > 0 then
        text = L.target_credits
        clr = COLOR_YELLOW
      end

      if text then
        w, h = surface.GetTextSize( text )
        x = x_orig - w / 2
        y = y + h + 5

        draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
        draw.SimpleText( text, font, x, y, clr )
      end
    end
    local function AdvDisguiseDraw()
      local client = LocalPlayer()
      if not IsValid(client) then return end
      if not client:GetNWBool("AdvDisguiseInDisguise") then return end

      surface.SetFont("TabLarge")
      surface.SetTextColor(255, 0, 0, 230)

      local text = "You are disguised as " .. client:GetNWString("AdvDisguiseName")
      local w, h = surface.GetTextSize(text)

      surface.SetTextPos(36, ScrH() - 150 - h)
      surface.DrawText(text)
    end
    hook.Add("HUDPaint","AdvDisguiseDraw", AdvDisguiseDraw)

  end
  hook.Add( 'InitPostEntity', 'AdvDisguiserInit', AdvDisguiserInit )
  timer.Simple( 5, function()
      function RADIO:GetTargetType()
        if not IsValid(LocalPlayer()) then return end
        local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)

        if not trace or (not trace.Hit) or (not IsValid(trace.Entity)) then return end

        local ent = trace.Entity

        if ent:IsPlayer() then
          if ent:GetNWBool("disguised", false) then
            return "quick_disg", true
          elseif ent:GetNWBool("AdvDisguiseInDisguise", false) then
            if IsValid(ent:GetNWEntity("AdvDisguiseEnt",nil)) then
              return ent:GetNWEntity("AdvDisguiseEnt",nil), false
            else
              return nil, false
            end

          else
            return ent, false
          end
        elseif ent:GetClass() == "prop_ragdoll" and CORPSE.GetPlayerNick(ent, "") != "" then
          if DetectiveMode() and not CORPSE.GetFound(ent, false) then
            return "quick_corpse", true
          else
            return ent, false
          end
        end
      end
    end )
elseif SERVER then
  AddCSLuaFile("autorun/advdisguiser.lua")

  resource.AddFile("materials/VGUI/ttt/icon_adv_disguiser.vmt")
  local function AdvDisguiseReset()
    for _,ply in pairs (player.GetAll()) do
      ply:SetNWString( "AdvDisguiseName", "" )
      ply:SetNWBool( "AdvDisguiseIsDetective", false )
      ply:SetNWInt( "AdvDisguiseKarma", 0 )
      ply:SetNWEntity( "AdvDisguiseEnt", nil )
      ply:SetNWBool( "AdvDisguiseInDisguise", false )
    end
  end
  hook.Add("TTTPrepareRound","AdvDisguiseReset ", AdvDisguiseReset )

end

function SWEP:PrimaryAttack()

  if not IsValid(self.Owner) then return end
  if CurTime() - self:LastShootTime( ) < self.Primary.Delay then return end
  self.Owner:LagCompensation(true)

  local spos = self.Owner:GetShootPos()
  local sdest = spos + (self.Owner:GetAimVector() * 70)

  local kmins = Vector(1,1,1) * -10
  local kmaxs = Vector(1,1,1) * 10

  local tr = util.TraceHull({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

  -- Hull might hit environment stuff that line does not hit
  if not IsValid(tr.Entity) then
    tr = util.TraceLine({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL})
  end

  local hitEnt = tr.Entity

  -- effects
  if IsValid(hitEnt) then
    self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )

    if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
    end
    self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
  else
    self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
  end

  if SERVER then
    self.Owner:SetAnimation( PLAYER_ATTACK1 )
  end

  if SERVER and IsValid(self.Owner) and tr.Hit and tr.HitNonWorld and IsValid(hitEnt) then
    if hitEnt:IsPlayer() then
      self.Owner:SetNWString( "AdvDisguiseName", hitEnt:Nick() )
      self.Owner:SetNWBool( "AdvDisguiseIsDetective", hitEnt:IsDetective() )
      self.Owner:SetNWInt( "AdvDisguiseKarma", hitEnt:GetBaseKarma() )
      self.Owner:SetNWEntity( "AdvDisguiseEnt", hitEnt )
      DamageLog("ADVANCED DISGUISER:\t " .. self.Owner:Nick() .. " [" .. self.Owner:GetRoleString() .. "]" .. " stole " .. hitEnt:Nick() .. " [" .. hitEnt:GetRoleString() .. "]" .. "'s identity.")

      self.Owner:SetModel(hitEnt:GetModel())
      self.Owner:ChatPrint( "Retrieved "..hitEnt:Nick().."'s identity successfully.")
    elseif hitEnt:GetClass() == "prop_ragdoll" and hitEnt.player_ragdoll then

      local name = CORPSE.GetPlayerNick(hitEnt, "")

      if name!="" then
        self.Owner:SetNWString( "AdvDisguiseName", name )
        self.Owner:SetNWBool( "AdvDisguiseIsDetective", hitEnt.was_role == ROLE_DETECTIVE )
        if IsValid(player.GetByUniqueID( hitEnt.uqid )) then
          self.Owner:SetNWInt( "AdvDisguiseKarma", player.GetByUniqueID( hitEnt.uqid ):GetBaseKarma())
          self.Owner:SetNWEntity( "AdvDisguiseEnt" , player.GetByUniqueID( hitEnt.uqid ))
          self.Owner:SetModel(hitEnt:GetModel())
        else
          self.Owner:SetNWInt( "AdvDisguiseKarma", self.Owner():GetBaseKarma())
          self.Owner:SetNWEntity( "AdvDisguiseEnt" , nil)
          self.Owner:SetModel(hitEnt:GetModel())
        end
        self.Owner:ChatPrint( "Retrieved "..name.."'s identity successfully!")

        DamageLog("ADVANCED DISGUISER:\t " .. self.Owner:Nick() .. " [" .. self.Owner:GetRoleString() .. "]" .. " stole " .. name .." [dead]" .. "'s identity.")
      end

    end
  end

  self.Owner:LagCompensation(false)
end

function SWEP:SecondaryAttack()

  if not IsValid(self.Owner) then return end
  if not SERVER then return end

  if self.Owner:GetNWBool("AdvDisguiseInDisguise") then
    self.Owner:SetNWBool("AdvDisguiseInDisguise",false)
  else
    if self.Owner:GetNWBool("AdvDisguiseName","") != "" then
      self.Owner:SetNWBool("AdvDisguiseInDisguise",true)
    else
      self.Owner:ChatPrint( "You need to retrieve an identity first!")
    end
  end

end

if CLIENT then
  function SWEP:Initialize()
    self:AddHUDHelp("MOUSE1 Steal identity", "MOUSE2 Use stolen identity", false)

    return self.BaseClass.Initialize(self)
  end

  function SWEP:DrawWorldModel()
    if not IsValid(self.Owner) then
      self:DrawModel()
    end
  end
end

function SWEP:Reload()
  return false
end

function SWEP:Deploy()
  if SERVER and IsValid(self.Owner) then
    self.Owner:DrawViewModel(false)
  end
  return true
end

function SWEP.PreDrop(wep)
  wep.Owner:SetNWBool( "AdvDisguiseInDisguise", false )
end
