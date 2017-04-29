if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddFile( "materials/vgui/ttt/icon_timer.vmt" )
  resource.AddWorkshop("611873052")
  util.AddNetworkString("MFMessage")
end

if CLIENT then
  SWEP.PrintName = "Mirror Fate"
  SWEP.Author = "Lord KhrumoX"
  SWEP.Slot = 7
  SWEP.Icon = "vgui/ttt/icon_timer"
  SWEP.EquipMenuData = {
    type = "item_weapon",
    name = "Mirror Fate",
    desc = "If you get killed, your assassin will too! \nIf your assassin has this item too,\nit will have no effect.\nLeft-/Right-Click to adjust the death.\nReload to Reset!"
  }
end

SWEP.ViewModel = "models/weapons/v_watch.mdl"
SWEP.WorldModel = "models/weapons/w_watch.mdl"

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR,ROLE_DETECTIVE}
SWEP.ViewModelFlip = true
SWEP.AutoSpawnable = false

SWEP.AmmoEnt = "nil"

SWEP.InLoadoutFor = { nil }

function SWEP:OnDrop()
  self:Remove()
end

SWEP.AllowDrop = false

SWEP.IsSilent = false

SWEP.NoSights = false
if CLIENT then
  function SWEP:PrimaryAttack() end
  function SWEP:SecondaryAttack() end
  function SWEP:Reload() end
end

if SERVER then
  function SWEP:WasBought(buyer)
    if IsValid(buyer) then
      buyer.fatemode = 1
      buyer.fatetimemode = 30
    end
  end
  function SWEP:PrimaryAttack()
    local ply = self.Owner
    ply.fatemode = ply.fatemode + 1
    if ply.fatemode > 7 then
      ply.fatemode = 1
    end
    net.Start("MFMessage")
    net.WriteInt(ply.fatemode, 8)
    net.Send(ply)
  end

  function SWEP:SecondaryAttack()
   local ply = self.Owner
    local mode = ply.fatetimemode
	if mode == 30 then
      ply.fatetimemode = 40
    elseif mode == 40 then
      ply.fatetimemode = 50
    elseif mode == 50 then
  	  ply.fatetimemode = 60
  	elseif mode == 60 then
      ply.fatetimemode = 30
	end
  	net.Start("MFMessage")
    net.WriteInt(12, 8)
  	net.WriteInt(ply.fatetimemode, 8)
    net.Send(ply)
  end

  local function SendMFMessages(victim, killer)
  	if IsValid(killer) then
  		net.Start("MFMessage")
  		net.WriteInt(11,8)
  		net.Send(killer)
  	end
  	if IsValid(victim) then
  		net.Start("MFMessage")
  		net.WriteInt(10,8)
  		net.Send(victim)
  	end
  end
  
  local function ConfirmBody(ply)
  	local corpse
  	for _, ent in pairs( ents.FindByClass( "prop_ragdoll" )) do
  		if ent.sid == ply:SteamID() and IsValid(ent) then
  			corpse = ent
  		end
  	end
  	if corpse then
  		CORPSE.SetFound(corpse, true)
  	end
  	return corpse
  end

  local function MFHoly(victim, killer)
	killer:EmitSound("gamefreak/holy.wav")
    timer.Create("MFHoly" .. killer:EntIndex(), 1, 5, function()
      killer:SetGravity(0.01)
    	killer:SetVelocity(Vector(0,0, 250))
    	if timer.RepsLeft("MFHoly" .. killer:EntIndex()) == 0 then
    		local fate = ents.Create("weapon_ttt_mirrorfate")
    		local dmginfo = DamageInfo()
    		dmginfo:SetDamage(10000)
    		dmginfo:SetAttacker(victim)
    		dmginfo:SetInflictor(fate)
    		dmginfo:SetDamageType(DMG_FALL)
    		killer:TakeDamageInfo(dmginfo)
    		SendMFMessages(victim, killer)
    		killer:SetGravity(1)
    		killer:SetNWBool("body_found", true)
        local corpse = ConfirmBody(killer)
        corpse:Remove()
    	end
    end)

  end

  local function MFThriller(victm, killer)
  	killer:EmitSound("gamefreak/thrilcut.wav")
  	killer:GodEnable()
  	killer:Freeze(true)
    	timer.Create( "MFThriller" .. killer:EntIndex(), 1, 14, function()
    	  local danceChange = math.random(1, 2)
    	  if danceChange == 1 then
    		  killer:DoAnimationEvent( ACT_GMOD_GESTURE_TAUNT_ZOMBIE, 1641 )
    	  else
    		  killer:DoAnimationEvent( ACT_GMOD_TAUNT_DANCE, 1642 )
    	  end
    	  if !killer:IsFrozen() then killer:Freeze(true) end
    	  if timer.RepsLeft("MFThriller" .. killer:EntIndex()) == 0 then
      		if killer:IsTerror() then
      			killer:GodDisable()
      			killer:Freeze(false)
      			local totalHealth = killer:Health()
      			local inflictWep = ents.Create('weapon_ttt_thriller')
      			killer:TakeDamage( totalHealth, victim, inflictWep )
      			SendMFMessages(victim, killer)
      		end
    	  end
    	end)
  end

  local function MFOneHit(victim, killer)
  	killer.MFOneHit = true
  	killer.MFEnt = victim
  end

  local function MFBulletSelfDamage(victim, killer)
  	killer.MFBullet = true
  	killer.MFEnt = victim
  end

  local function MFHeartAttack(victim, killer)
    local fate = ents.Create("weapon_ttt_mirrorfate")
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(10000)
    dmginfo:SetAttacker(victim)
    dmginfo:SetInflictor(fate)
    dmginfo:SetDamageType(DMG_GENERIC)
    killer:TakeDamageInfo(dmginfo)
	  SendMFMessages(victim, killer)
  end

  local function MFBurn(victim, killer)
    local fate = ents.Create("weapon_ttt_mirrorfate")
    local dmg = DamageInfo()
    dmg:SetDamage(5)
    dmg:SetAttacker(victim)
    dmg:SetInflictor(fate)
    dmg:SetDamageType(DMG_BURN)
    killer:EmitSound("gamefreak/evillaugh.mp3")
    timer.Create("BurnInHellMirrorfate" .. killer:EntIndex(), 0.25, 0, function()
        if killer:Alive() and killer:IsTerror() and IsValid(killer) then
          killer:TakeDamageInfo(dmg)
          killer:Ignite(0.2)
        elseif IsValid(killer) and !killer:IsTerror() then
		      SendMFMessages(victim, killer)
          timer.Remove("BurnInHellMirrorfate" .. killer:EntIndex())
        end
      end )
  end

  local function MFExplode(victim, killer)
    local fate = ents.Create("weapon_ttt_mirrorfate")

    local dmginfo = DamageInfo()
    dmginfo:SetDamage(10000)
    dmginfo:SetAttacker(victim)
    dmginfo:SetDamageType(DMG_BLAST)
    dmginfo:SetInflictor(fate)

    local effectdata = EffectData()
    killer:EmitSound( Sound ("ambient/explosions/explode_4.wav") )
    util.BlastDamageInfo(dmginfo, killer:GetPos(), 200)
    effectdata:SetStart( killer:GetPos() + Vector(0,0,10) )
    effectdata:SetOrigin( killer:GetPos() + Vector(0,0,10) )
    effectdata:SetScale( 1 )
    util.Effect( "HelicopterMegaBomb", effectdata )
	  SendMFMessages(victim, killer)
  end

  local plymeta = FindMetaTable("Player")

  function plymeta:TTTMirrorfate(victim)
    if victim.fatemode == 1 then
		  MFHeartAttack(victim, self)
    elseif victim.fatemode == 2 then
		  MFBurn(victim, self)
    elseif victim.fatemode == 3 then
		  MFExplode(victim, self)
  	elseif victim.fatemode == 4 then
  		MFOneHit(victim, self)
  	elseif victim.fatemode == 5 then
  		MFBulletSelfDamage(victim, self)
  	elseif victim.fatemode == 6 then
		  MFThriller(victim, self)
    elseif victim.fatemode == 7 then
      MFHoly(victim, self)
    else
		  MFHeartAttack(victim, self)
    end
  end

  local function KillTheKillerMirrorfate(victim, killer)
    timer.Create( "MirrorFatekill" .. killer:EntIndex(), victim.fatetimemode or 30 , 1, function()
      if IsValid(victim) and IsValid(killer) and killer:IsTerror() then
        killer:TTTMirrorfate(victim)
      elseif IsValid(victim) and (!IsValid(killer) or !killer:IsTerror()) then
        victim:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer is already dead!")
      end
    end)
  end

  local function Mirrorfate( victim, killer, damageinfo )
    if IsValid(killer) and IsValid(victim) and victim:HasWeapon("weapon_ttt_mirrorfate") and !killer:HasWeapon("weapon_ttt_mirrorfate") then
      KillTheKillerMirrorfate(victim, killer)
    end
    if IsValid(victim) and timer.Exists("MirrorFatekill" .. victim:EntIndex()) then
      timer.Remove("MirrorFatekill" .. victim:EntIndex())
    end
  end

  local function ResetMirrorFate(ply)
    timer.Remove("MirrorFatekill" .. ply:EntIndex())
    timer.Remove("BurnInHellMirrorfate" .. ply:EntIndex())
  	timer.Remove("MFThriller" .. ply:EntIndex())
  	timer.Remove("MFHoly" .. ply:EntIndex())
    ply.fatemode = 1
    ply.fatetimemode = 30
  	ply.MFBullet = false
  	ply.MFOneHit = false
  	ply.MFEnt = nil
  end

  hook.Add("DoPlayerDeath" , "MirrorfateKillhim" , Mirrorfate )
  hook.Add("PlayerSpawn", "ResetMirrorFate", ResetMirrorFate)
  hook.Add("TTTPrepareRound","ResetMirrorFate", function()
      for key,ply in pairs(player.GetAll()) do
        ResetMirrorFate(ply)
      end
  end)

  local function MFBulletHook( ent, bullet)
  	if ent.MFBullet then
  		local dmg = DamageInfo()
  		local fate = ents.Create("weapon_ttt_mirrorfate")
  		dmg:SetDamage(bullet.Damage)
  		dmg:SetAttacker(ent)
  		dmg:SetInflictor(fate)
  		dmg:SetDamageType(DMG_BULLET)
  		ent:TakeDamageInfo(dmg)
  		SendMFMessages(killer.MFEnt, ent)
  		return false
  	end
  end

  local function MFOneHitHook(ent, dmg)
  	if ent.MFOneHit then
  		ent.MFOneHit = false
  		local dmg = DamageInfo()
  		local fate = ents.Create("weapon_ttt_mirrorfate")
  		dmg:SetDamage(10000)
  		dmg:SetAttacker(ent)
  		dmg:SetInflictor(fate)
  		dmg:SetDamageType(DMG_BULLET)
  		ent:TakeDamageInfo(dmg)
  		SendMFMessages(ent.MFEnt, ent)
  		return true
  	end
  end

  hook.Add("EntityFireBullets", "MFBullets", MFBulletHook)
  hook.Add("EntityTakeDamage", "MFDamage", MFOneHitHook)
elseif CLIENT then
  local function MFMessage()
    local mode = net.ReadInt(8)
    if mode == 1 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will die on a heart-attack!")
    elseif mode == 2 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will burn in Hell!")
    elseif mode == 3 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will explode!")
	elseif mode == 4 then
	  chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will get one hit by any damage!")
	elseif mode == 5 then
	  chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will damage himself every time he shoots!")
	elseif mode == 6 then
	  chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will dance the thriller!")
	elseif mode == 7 then
	  chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will die a holy death!")
    elseif mode == 11 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"You have experienced the " ,Color(255,0,0) ,"fate " ,Color(250,250,250) ,"your victim chose." )
    elseif mode == 10 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer has experienced your choosed " ,Color(255,0,0), "fate." )
	elseif mode == 12 then
	  chat.AddText("Mirror Fate: ", Color(250,250,250) ,"It will now take " .. net.ReadInt(8) .. " second until your killer will experience your choosed " ,Color(255,0,0), "fate." )
    end
    chat.PlaySound()
  end
  net.Receive("MFMessage", MFMessage)
end
