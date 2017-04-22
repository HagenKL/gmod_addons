if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddWorkshop("606792331")
  util.AddNetworkString("TTTAdvDisguiseSuccess")
  util.AddNetworkString("TTTAdvDisguiseIdentity")
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
SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy
SWEP.LimitedStock = true -- only buyable once

SWEP.IsSilent = true

SWEP.DeploySpeed = 4-- Pull out faster than standard guns

if CLIENT then

	local function DrawPropSpecLabelsAdvDisguiser(client)
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
			 local _, healthcolor = util.HealthToString(ply:Health(), ply:GetMaxHealth())
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
	
	local minimalist = GetConVar("ttt_minimal_targetid")
	local ring_tex = surface.GetTextureID("effects/select_ring")
	local GetLang = LANG.GetUnsafeLanguageTable

    local function AdvDisguiserInit()

	   local client = LocalPlayer()

	   local L = GetLang()

	   local trace = client:GetEyeTrace(MASK_SHOT)
	   local ent = trace.Entity
	   if (ent:IsPlayer() and !ent:GetNWBool("AdvDisguiseInDisguise", false)) or !ent:IsPlayer() then return end
	   if (not IsValid(ent)) or ent.NoTarget then return end
      
      DrawPropSpecLabelsAdvDisguiser(client)
	  
	  local target_traitor = false
	  local target_detective = false
	  local target_corpse = false
	  
      local text = nil
      local color = COLOR_WHITE

      local minimal = minimalist:GetBool()

      if ent:GetNWBool("disguised", false) then
         client.last_id = nil

         if client:IsTraitor() or client:IsHunter() or client:IsSpec() then
            text = ent:Nick() .. L.target_disg
         else
            -- Do not show anything
            return
         end

         color = COLOR_RED

      elseif ((client:IsTraitor() or (ent.IsHunter and ent:IsHunter()))) and (ent:IsTraitor() or (ent.IsHunter and ent:IsHunter())) or client:IsSpec() then
        text = ent:Nick() .. " (Disguised as " .. ent:GetNWString("AdvDisguiseName") .. ")"
        color = COLOR_RED
      else

        text = ent:GetNWString("AdvDisguiseName")
        client.last_id = ent:GetNWEntity("AdvDisguiseEnt",nil)
      end

      -- in minimalist targetID, colour nick with health level
      if minimal then
        _, color = util.HealthToString(ent:Health(), ent:GetMaxHealth())
      end

      if (client:IsTraitor() or (client.IsHunter and client:IsHunter())) and GetRoundState() == ROUND_ACTIVE then
        target_traitor = ent:GetNWEntity("AdvDisguiseIsTraitor")
      end

      target_detective = ent:GetNWBool("AdvDisguiseIsDetective")

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

          y = y + h + 4
        end

        -- Minimalist target ID only draws a health-coloured nickname, no hints, no
        -- karma, no tag
        if minimal then return end

        -- Draw subtitle: health or type
        local clr = rag_color
        text, clr = util.HealthToString(ent:Health(), ent:GetMaxHealth())

          -- HealthToString returns a string id, need to look it up
        text = L[text]
        font = "TargetIDSmall2"

        surface.SetFont( font )
        w, h = surface.GetTextSize( text )
        x = x_orig - w / 2

        draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
        draw.SimpleText( text, font, x, y, clr )

        font = "TargetIDSmall"
        surface.SetFont( font )

        -- Draw second subtitle: karma
        if KARMA.IsEnabled() then
          text, clr = util.KarmaToString(ent:GetNWBool("AdvDisguiseInDisguise") and ent:GetNWInt("AdvDisguiseKarma"))

          text = L[text]

          w, h = surface.GetTextSize( text )
          y = y + h + 5
          x = x_orig - w / 2

          draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
          draw.SimpleText( text, font, x, y, clr )
        end

        text = nil

        if IsValid(ent:GetNWEntity("AdvDisguiseEnt",nil)) and ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag and ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag.txt then
          text = L[ ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag.txt ]
          clr = ent:GetNWEntity("AdvDisguiseEnt",nil).sb_tag.color
        end

        if text then
          w, h = surface.GetTextSize( text )
          x = x_orig - w / 2
          y = y + h + 5

          draw.SimpleText( text, font, x+1, y+1, COLOR_BLACK )
          draw.SimpleText( text, font, x, y, clr )
        end
        return false
    end

  hook.Add( "HUDDrawTargetID", "AdvDisguiserInit", AdvDisguiserInit )
  
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

elseif SERVER then

  local function AdvDisguiseReset()
    for _,ply in pairs (player.GetAll()) do
      ply:SetNWString( "AdvDisguiseName", "" )
      ply:SetNWBool( "AdvDisguiseIsDetective", false )
	  ply:SetNWBool( "AdvDisguiseIsTraitor", false )
      ply:SetNWInt( "AdvDisguiseKarma", 0 )
      ply:SetNWEntity( "AdvDisguiseEnt", nil )
      ply:SetNWBool( "AdvDisguiseInDisguise", false )
      ply:SetNWString("AdvDisguiserModel","")
      ply.OldModel = ""
    end
  end
  hook.Add("TTTPrepareRound","AdvDisguiseReset ", AdvDisguiseReset )

  function SWEP:SecondaryAttack()

  if not IsValid(self.Owner) then return end
  self:SetNextSecondaryFire(CurTime() + 0.2)
  
  local owner = self.Owner
  if owner:GetNWBool("AdvDisguiseInDisguise") then
    owner:SetNWBool("AdvDisguiseInDisguise",false)
    if owner.OldModel then
      owner:SetModel(owner.OldModel)
    end
  else
    if owner:GetNWBool("AdvDisguiseName","") != "" then
      owner:SetNWBool("AdvDisguiseInDisguise",true)
      owner.OldModel = owner:GetModel()
      if owner:GetNWString("AdvDisguiserModel", "") != "" then
        owner:SetModel(owner:GetNWString("AdvDisguiserModel", ""))
      end
    else
      net.Start("TTTAdvDisguiseIdentity")
      net.Send(self.Owner)
    end
  end

end

end

function SWEP:PrimaryAttack()

  if not IsValid(self.Owner) then return end
  self:SetNextPrimaryFire(CurTime() + 0.5)
  if CurTime() - self:LastShootTime( ) < self.Primary.Delay then return end

  local spos = self.Owner:GetShootPos()
  local sdest = spos + (self.Owner:GetAimVector() * 70)

  local kmins = Vector(1,1,1) * -10
  local kmaxs = Vector(1,1,1) * 10

  self.Owner:LagCompensation(true)

  local tr = util.TraceHull({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

  -- Hull might hit environment stuff that line does not hit
  if not IsValid(tr.Entity) then
    tr = util.TraceLine({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL})
  end

  local hitEnt = tr.Entity

  self.Owner:LagCompensation(false)

  -- effects
  if IsValid(hitEnt) then
    self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )

    self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
  else
    self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
  end

  if SERVER and IsValid(self.Owner) and tr.Hit and tr.HitNonWorld and IsValid(hitEnt) then
    if hitEnt:IsPlayer() and not hitEnt:IsSpec() then
      self.Owner:SetNWString( "AdvDisguiseName", hitEnt:Nick() )
      self.Owner:SetNWBool( "AdvDisguiseIsDetective", hitEnt:IsDetective() )
	  self.Owner:SetNWBool( "AdvDisguiseIsTraitor", hitEnt:IsTraitor() )
      self.Owner:SetNWInt( "AdvDisguiseKarma", hitEnt:GetBaseKarma() )
      self.Owner:SetNWEntity( "AdvDisguiseEnt", hitEnt )
      self.Owner:SetNWString("AdvDisguiserModel",hitEnt:GetModel())


      DamageLog("ADVANCED DISGUISER:\t " .. self.Owner:Nick() .. " [" .. self.Owner:GetRoleString() .. "]" .. " stole " .. hitEnt:Nick() .. " [" .. hitEnt:GetRoleString() .. "]" .. "'s identity.")
      net.Start("TTTAdvDisguiseSuccess")
      net.WriteString(hitEnt:Nick())
      net.Send(self.Owner)
    elseif hitEnt:GetClass() == "prop_ragdoll" and hitEnt.player_ragdoll then

      local name = CORPSE.GetPlayerNick(hitEnt, "")

      if name != "" then
        self.Owner:SetNWString( "AdvDisguiseName", name )
        self.Owner:SetNWBool( "AdvDisguiseIsDetective", hitEnt.was_role == ROLE_DETECTIVE )
		self.Owner:SetNWBool( "AdvDisguiseIsTraitor", hitEnt.was_role == ROLE_TRAITOR )
        self.Owner:SetNWString("AdvDisguiserModel",hitEnt:GetModel())
        if IsValid(player.GetByUniqueID( hitEnt.uqid )) then
          self.Owner:SetNWInt( "AdvDisguiseKarma", player.GetByUniqueID( hitEnt.uqid ):GetBaseKarma())
          self.Owner:SetNWEntity( "AdvDisguiseEnt" , player.GetByUniqueID( hitEnt.uqid ))
        else
          self.Owner:SetNWInt( "AdvDisguiseKarma", self.Owner():GetBaseKarma())
          self.Owner:SetNWEntity( "AdvDisguiseEnt" , nil)
        end
        net.Start("TTTAdvDisguiseSuccess")
        net.WriteString(name)
        net.Send(self.Owner)

        DamageLog("ADVANCED DISGUISER:\t " .. self.Owner:Nick() .. " [" .. self.Owner:GetRoleString() .. "]" .. " stole " .. name .." [dead]" .. "'s identity.")
      end

    end
  end

end

if CLIENT then
  function SWEP:Initialize()
    self:AddHUDHelp("MOUSE1 Steal identity", "MOUSE2 Use stolen identity", false)

    return self.BaseClass.Initialize(self)
  end

  net.Receive("TTTAdvDisguiseSuccess",function()
    local printname = net.ReadString()
    chat.AddText("Advanced Disguiser: ", COLOR_WHITE, "Retrieved " .. printname .. "'s identity successfully!")
    chat.PlaySound()
  end)
  net.Receive("TTTAdvDisguiseIdentity",function()
    chat.AddText("Advanced Disguiser: ", COLOR_WHITE, "You need to retrieve an identity first!")
    chat.PlaySound()
  end)
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
  if wep.Owner.OldModel then
      wep.Owner:SetModel(wep.Owner.OldModel)
  end
end
