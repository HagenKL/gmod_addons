////////////////////
//Dead Ringer Swep//
///////Update///////
////by NECROSSIN////
////////////////////
///TTT Convert by///
///////PORTER///////
////////////////////
////TTT Fixed by////
/////GAMEFREAK//////
////////////////////

--Updated: 24 January 2010
--Converted : 01 May 2014
--Fixed : 1 December 2016

----------------------------
--////////////////////////--
--////////////////////////--
----------------------------

--was -- this SWEP uses models, textures and sounds from TF2, so be sure that you have it if you dont want to see an ERROR instead of swep model and etc...
--now -- included models, textures and sounds from TF2, so u don't need to install TeamFortress2...

--------------------------------------------------------------------------
if SERVER then
  resource.AddWorkshop("810154456")
  AddCSLuaFile("shared.lua")
  AddCSLuaFile("gamemodes/terrortown/entities/effects/druncloak.lua")
  util.AddNetworkString("TTT_DeadRingerSound")
  util.AddNetworkString("DRChangeMaterial")
end

--------------------------------------------------------------------------

if ( CLIENT ) then
  SWEP.PrintName = "Dead Ringer"
  SWEP.Slot = 6

  SWEP.EquipMenuData = {
    type = "item_weapon",
    desc = "Fake your death!\nPrimary - turn on.\nSecondary - turn off or drop cloak."
  };

  SWEP.Icon = "vgui/ttt/icon_deadringer"

  SWEP.Author = "NECROSSIN (fixed by Niandra Lades / Converted by Porter / Fixed by Gamefreak)"
  SWEP.DrawAmmo = false
  SWEP.DrawCrosshair = false
  SWEP.ViewModelFOV = 70
  SWEP.ViewModelFlip = false
  SWEP.CSMuzzleFlashes = false
  SWEP.WepSelectIcon = surface.GetTextureID("models/ttt/c_pocket_watch/c_pocket_watch.vtf") -- texture from TF2

  SWEP.IconLetter = "G"

  function DrawDRHUD()
    --here goes the new HUD
    if LocalPlayer():GetNWInt("DRStatus") == 1 or LocalPlayer():GetNWInt("DRStatus") == 3 or LocalPlayer():GetNWInt("DRStatus") == 4 and LocalPlayer():Alive() and LocalPlayer():IsTerror() then
      local background = surface.GetTextureID("vgui/ttt/misc_ammo_area_red")
      local w,h = surface.GetTextureSize(surface.GetTextureID("vgui/ttt/misc_ammo_area_red"))
      surface.SetTexture(background)
      surface.SetDrawColor(255,255,255,255)
      surface.DrawTexturedRect(13, ScrH() - h - 240, w * 5, h * 5 )

      local energy = math.max(LocalPlayer():GetNWInt("DRCharge"), 0)
      draw.RoundedBox(2,44, ScrH() - h - 208, (energy / 8) * 77, 15, Color(255,222,255,255))
      surface.SetDrawColor(255,255,255,255)
      surface.DrawOutlinedRect(44, ScrH() - h - 208, 77, 15)
      draw.DrawText("CLOAK", "DebugFixed",65, ScrH() - h - 190, Color(255,255,255,255))
    end
  end
  hook.Add("HUDPaint", "drawdrhud", DrawDRHUD)
end
-------------------------------------------------------------------

SWEP.Category = "Spy"

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.Purpose = "Fake your death!"

SWEP.Instructions = "Primary - turn on.\nSecondary - turn off or drop cloak."

SWEP.ViewModel = "models/ttt/v_models/v_watch_pocket_spy.mdl"
SWEP.WorldModel = "models/ttt/w_models/w_pocket_watch.mdl"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Category = "Dead Ringer"
SWEP.Kind = WEAPON_EQUIP1
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true
SWEP.Base = "weapon_tttbase"
SWEP.AllowDrop = true
SWEP.HoldType = "slam"
SWEP.NoSights = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

-----------------------------------
function SWEP:Initialize()
  self:SetHoldType("slam")
end
-----------------------------------
function SWEP:Deploy()
  self:SendWeaponAnim( ACT_VM_DRAW )
  return true
end
-----------------------------------
function DRThink()
  if SERVER then
    for _, ply in pairs(player.GetAll()) do
      if ply:IsValid() and !ply:GetNWBool("DRDead") and ply:GetNWInt("DRStatus") == 4 then
        if ply:GetNWInt("DRCharge") < 8 then
          ply.drtimer = ply.drtimer or CurTime() + 0.1
          if CurTime() > ply.drtimer then
            ply.drtimer = CurTime() + 4
            ply:SetNWInt("DRCharge", ply:GetNWInt("DRCharge") + 1)
          end
        elseif ply:GetNWInt("DRCharge") >= 8 then
          ply:SetNWInt("DRStatus", 1)
          net.Start("TTT_DeadRingerSound")
          net.Send(ply)
        end
      elseif ply:IsValid() and ply:GetNWBool("DRDead") and ply:GetNWInt("DRStatus") == 3 then
        for _, v in pairs(ply:GetWeapons()) do
          v:SetNextPrimaryFire(CurTime() + 0.2)
          v:SetNextSecondaryFire(CurTime() + 0.2)
        end
        ply:DrawWorldModel(false)
        if ply:GetNWInt("DRCharge") <= 8 and ply:GetNWInt("DRCharge") > 0 then
          ply.cltimer = ply.cltimer or CurTime() + 2
          if CurTime() > ply.cltimer then
            ply.cltimer = CurTime() + 2
            ply:SetNWInt("DRCharge", ply:GetNWInt("DRCharge") - 1)
          end
        elseif ply:GetNWInt("DRCharge") == 0 then
          ply:DRuncloak()
        end
      end
    end
  end
end
hook.Add("Think", "DRThink", DRThink)

if SERVER then
  function DROwnerGetsDamage(ent,dmginfo)
    if ent:IsPlayer() then
      local ply = ent
      if ply:GetNWBool("DRDead") == false and ply:GetNWInt("DRStatus") == 1 then
        if dmginfo:GetDamage() >= 2 and dmginfo:GetDamage() < ent:Health() then
          ply:DRfakedeath(dmginfo)
        elseif ply:IsOnFire() then
          ply:DRfakedeath(dmginfo)
        end
      end
    end
  end

  function ResetDR(ply, attacker)
    if ply:IsValid() and ply:GetNWBool("DRDead") and ply:GetNWInt("DRStatus") == 3 then
      ply:DRuncloak()
    end
    ply:SetNWInt("DRStatus",0)
    ply:SetNWInt("DRCharge", 8 )
  end

  function DRRoundreset()
    for k,v in pairs(player.GetAll()) do
      v:GetViewModel():SetMaterial("")
      v:SetMaterial("")
      v:SetColor(255,255,255,255)
      v:SetNWInt("DRStatus",0)
      v:SetNWBool("DRDead",false)
      v:SetNWInt("DRCharge", 8 )
    end
    net.Start("DRChangeMaterial")
    net.WriteBool(false)
    net.Broadcast()
  end

  function DRSpawnReset( ply )
    if ply:GetNWBool("DRDead") then
      ply:GetViewModel():SetMaterial("")
      ply:SetMaterial("")
      ply:SetColor(255,255,255,255)
    end
    ply:SetNWInt("DRStatus",0)
    ply:SetNWBool("DRDead",false)
    ply:SetNWInt("DRCharge", 8 )
  end

  function UncloakKey( ply, key )
    if ply:IsValid() and ply:GetNWBool("DRDead") and ply:GetNWInt("DRStatus") == 3 and key == IN_ATTACK2 then
      ply:DRuncloak()
    end
  end
  hook.Add("KeyPress", "DRUncloaking", UncloakKey)
  hook.Add("PlayerSpawn", "DRSpawnReset", DRSpawnReset )
  hook.Add("TTTPrepareRound", "DRRoundreset", DRRoundreset)
  hook.Add("EntityTakeDamage", "DROwnergetsdamage", DROwnerGetsDamage)
  hook.Add("DoPlayerDeath", "DRReset", ResetDR)
end

function DRFootstepsDisable( ply )
  if ply:Alive() and ply:IsValid() and ply:GetNWBool("DRDead") == true and ply:GetNWInt("DRStatus") == 3 then
    return true
  end
end

hook.Add("PlayerFootstep","DeadRingerFootsteps",DRFootstepsDisable)
-------------------------------------------------------------------------------

function SWEP:PrimaryAttack()
  if self.Owner:GetNWBool("DRDead") == false and self.Owner:GetNWInt("DRStatus") != 1 and self.Owner:GetNWInt("DRStatus") != 4 then
    self.Owner:SetNWInt("DRStatus",1)
    self:EmitSound("buttons/blip1.wav", 100, 100, 1, CHAN_AUTO)
    if self.Owner:GetNWInt("DRCharge") < 8 then
      self.Owner:SetNWInt("DRStatus",4)
    end
  else
    return
  end
end

function SWEP:SecondaryAttack()
  if self.Owner:GetNWBool("DRDead") == false and self.Owner:GetNWInt("DRStatus") != 2 then
    self.Owner:SetNWInt("DRStatus",2)
    self:EmitSound("buttons/blip1.wav", 100, 73, 1, CHAN_AUTO)
  else
    return
  end
end

function SWEP:PreDrop()
  if SERVER then
    local ply = self.Owner
    if IsValid(ply) then
      if ply:GetNWBool("DRDead") == true then
        self.Owner:DRuncloak()
      end
      ply:SetNWInt("DRStatus",0)
      ply:SetNWBool("DRDead", false)
    end
  end
end
-------------------------------------------------------------------------------------

local deathsounds = {
  Sound("player/death1.wav"),
  Sound("player/death2.wav"),
  Sound("player/death3.wav"),
  Sound("player/death4.wav"),
  Sound("player/death5.wav"),
  Sound("player/death6.wav"),
  Sound("vo/npc/male01/pain07.wav"),
  Sound("vo/npc/male01/pain08.wav"),
  Sound("vo/npc/male01/pain09.wav"),
  Sound("vo/npc/male01/pain04.wav"),
  Sound("vo/npc/Barney/ba_pain06.wav"),
  Sound("vo/npc/Barney/ba_pain07.wav"),
  Sound("vo/npc/Barney/ba_pain09.wav"),
  Sound("vo/npc/Barney/ba_ohshit03.wav"), --heh
  Sound("vo/npc/Barney/ba_no01.wav"),
  Sound("vo/npc/male01/no02.wav"),
  Sound("hostage/hpain/hpain1.wav"),
  Sound("hostage/hpain/hpain2.wav"),
  Sound("hostage/hpain/hpain3.wav"),
  Sound("hostage/hpain/hpain4.wav"),
  Sound("hostage/hpain/hpain5.wav"),
  Sound("hostage/hpain/hpain6.wav")
};

local plymeta = FindMetaTable( "Player" );

-- Mostly code from TTT itself, to keep the bodys similar.
if SERVER then
  function plymeta:DRfakedeath(dmginfo)
    net.Start("DRChangeMaterial")
    net.WriteBool(true)
    net.Send(self)
    self:SetNWBool("DRDead", true)
    self:SetNWInt("DRStatus", 3)
    self:SetColor(Color(0,0,0,0))
    self:SetMaterial( "models/effects/vol_light001" )
    self:SetRenderMode( RENDERMODE_TRANSALPHA )
    self:DrawShadow( false )
    self:Flashlight( false )
    self:AllowFlashlight(false)
    self:SetFOV(0, 0.2)
    local ownerwep = self:GetActiveWeapon()
    if ownerwep.Base == "weapon_tttbase" then
      ownerwep:SetIronsights(false)
    end

    DamageLog("DeadRinger: " .. self:Nick() .. " has faked his death.")

    ---------------------------
    --------"corpse"-------
    ---------------------------
    -- this is time to make our corpse

    -- create the ragdoll
    local rag = ents.Create("prop_ragdoll")

    rag:SetPos(self:GetPos())
    rag:SetModel(self:GetModel())
    rag:SetAngles(self:GetAngles())
    rag:SetColor(self:GetColor())
    rag:SetOwner(self)

    rag:Spawn(self)
    rag:Activate(self)

    -- nonsolid to players, but can be picked up and shot
    rag:SetCollisionGroup(GetConVar("ttt_ragdoll_collide"):GetBool() and COLLISION_GROUP_WEAPON or COLLISION_GROUP_DEBRIS_TRIGGER)
    timer.Simple( 1, function() if IsValid( rag ) then rag:CollisionRulesChanged() end end )

    -- flag this ragdoll as being a player's
    rag.player_ragdoll = true
    rag.sid = self:SteamID()

    rag.uqid = self:UniqueID()

    -- network data
    CORPSE.SetPlayerNick(rag, self)
    CORPSE.SetFound(rag, false)

    -- if someone searches this body they can find info on the victim and the
    -- death circumstances
    rag.equipment = self:GetEquipmentItems()
    rag.was_role = ROLE_INNOCENT
    rag.bomb_wire = false
    rag.dmgtype = dmginfo:GetDamageType()

    local wep = util.WeaponFromDamage(dmginfo)
    rag.dmgwep = IsValid(wep) and wep:GetClass() or ""

    rag.was_headshot = self.was_headshot and dmginfo:IsBulletDamage()
    if !self.was_headshot then
      sound.Play(table.Random(deathsounds), self:GetPos(), 90, 100)
    end
    rag.time = CurTime()
    rag.kills = table.Copy(self.kills)

    rag.killer_sample = nil

    -- position the bones
    local num = rag:GetPhysicsObjectCount() - 1
    local v = self:GetVelocity()

    -- bullets have a lot of force, which feels better when shooting props,
    -- but makes bodies fly, so dampen that here
    if dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_SLASH) then
      v = v / 5
    end

    for i = 0, num do
      local bone = rag:GetPhysicsObjectNum(i)

      if IsValid(bone) then
        local bp, ba = self:GetBonePosition(rag:TranslatePhysBoneToBone(i))
        if bp and ba then
          bone:SetPos(bp)
          bone:SetAngles(ba)
        end
        bone:SetVelocity(v)
      end
    end
  end

  -- here goes the uncloak function
  function plymeta:DRuncloak()
    net.Start("DRChangeMaterial")
    net.WriteBool(false)
    net.Send(self)
    self:SetNWBool("body_found", false)
    self:SetNWBool("DRDead",false)
    self:SetNWInt("DRStatus",4)
    self:GetViewModel():SetMaterial("")
    self:DrawShadow( true )
    self:SetMaterial( "" )
    self:SetRenderMode( RENDERMODE_NORMAL )
    self:Fire( "alpha", 255, 0 )
    self:SetColor(Color(255,255,255,255))
    self:SetNoDraw(false)
    self:SetNWInt("DRCharge", 0)
    self:AllowFlashlight(true)

    self:DrawWorldModel(true)

    self:SetMaterial("")

    self:EmitSound(Sound( "ttt/spy_uncloak_feigndeath.wav" ))
    DamageLog("DeadRinger: " .. self:Nick() .. " has uncloaked himself.")

    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    util.Effect( "druncloak", effectdata, true ,true )

    for _, rag in pairs(ents.GetAll()) do
      if rag:GetClass() == "prop_ragdoll" and rag:GetOwner() == self or rag.sid == self:SteamID() or rag.uqid == self:UniqueID() then
        rag:Remove()
      end
    end

  end
end
if (CLIENT) then
  function DRHidePlayer(ply)
    if ply:GetNWInt("DRDead") then
      if ply:GetNWBool("body_found", false) then
        return GROUP_FOUND
      else
        local client = LocalPlayer()
        if client:IsSpec() or client:IsActiveTraitor() or ((GAMEMODE.round_state != ROUND_ACTIVE) and client:IsTerror()) then
          return GROUP_NOTFOUND
        else
          return GROUP_TERROR
        end
      end
    end
  end
  hook.Add("TTTScoreGroup", "DRScoreBoard", DRHidePlayer)

  net.Receive("TTT_DeadRingerSound" , function()
      surface.PlaySound("ttt/recharged.wav")
    end )
  net.Receive("DRChangeMaterial",function()
      local enabled = net.ReadBool()
      if enabled then
        LocalPlayer():GetViewModel():SetMaterial( "models/props_c17/fisheyelens")
      else
        LocalPlayer():GetViewModel():SetMaterial("models/weapons/v_crowbar.mdl")
      end
    end)


    -- making the targetid invisible.
  /*function DROverrideTargetID()

    local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)
    local ent = trace.Entity
    if IsValid(ent) and IsPlayer(ent) and ent:GetNWInt("DRDead") then return false end

  end
  hook.Add("HUDDrawTargetID", "DRoverride", DROverrideTargetID)*/
end
