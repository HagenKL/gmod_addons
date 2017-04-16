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
    if ply.fatemode >= 4 then
      ply.fatemode = 1
    end
    local mode = ply.fatemode
    if mode == 1 then
      ply.fatemode = 30
    elseif mode == 2 then
      ply.fatemode = 40
    elseif mode == 3 then
      ply.fatemode = 50
    end
    net.Start("MFMessage")
    net.WriteInt(ply.fatemode, 8)
    net.Send(ply)
  end

  function KillTheKillerMirrorfate(victim, killer)
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

  hook.Add( "DoPlayerDeath" , "MirrorfateKillhim" , Mirrorfate )

  local function MFHeartAttack(victim, killer)
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(10000)
    dmginfo:SetAttacker(victim)
    dmginfo:SetDamageType(DMG_GENERIC)
    killer:TakeDamageInfo(dmginfo)
  end

  local function MFBurn(victim, killer)
    local dmg = DamageInfo()
    dmg:SetDamage(5)
    dmg:SetAttacker(victim)
    dmg:SetDamageType(DMG_BURN)
    killer:EmitSound("gamefreak/evillaugh.mp3")
    timer.Create("BurnInHellMirrorfate" .. killer:EntIndex(), 0.25, 0, function()
        if killer:Alive() and killer:IsTerror() and IsValid(killer) then
          killer:TakeDamageInfo(dmg)
          killer:Ignite(0.2)
        elseif IsValid(killer) and !killer:IsTerror() then
          timer.Remove("BurnInHellMirrorfate" .. killer:EntIndex())
        end
      end )
  end

  local function MFExplode(victim, killer)
    local effectdata = EffectData()
    killer:EmitSound( Sound ("ambient/explosions/explode_4.wav") )
    util.BlastDamage( victim, victim, killer:GetPos() , 200 , 1000 )
    effectdata:SetStart( killer:GetPos() + Vector(0,0,10) )
    effectdata:SetOrigin( killer:GetPos() + Vector(0,0,10) )
    effectdata:SetScale( 1 )
    util.Effect( "HelicopterMegaBomb", effectdata )
  end

  local plymeta = FindMetaTable("Player")

  function plymeta:TTTMirrorfate(victim)
    if victim.fatemode == 1 then
      MFHeartAttack(victim, self)
    elseif victim.fatemode == 2 then
      MFBurn(victim, self)
    elseif victim.fatemode == 3 then
      MFExplode(victim, self)
    else
      MFHeartAttack(victim, self)
    end
    net.Start("MFMessage")
    net.WriteInt(5,8)
    net.Send(self)
    net.Start("MFMessage")
    net.WriteInt(10,8)
    net.Send(victim)
  end

  local function ResetMirrorFate(ply)
    timer.Remove("MirrorFatekill" .. ply:EntIndex())
    timer.Remove("BurnInHellMirrorfate" .. ply:EntIndex())
    ply.fatemode = 1
    ply.fatetimemode = 30
  end

  hook.Add("PlayerSpawn", "ResetMirrorFate", function(ply)
    ResetMirrorFate(ply)
  end)
  hook.Add("TTTPrepareRound","ResetMirrorFate", function()
      for key,ply in pairs(player.GetAll()) do
        ResetMirrorFate(ply)
      end
  end)
elseif CLIENT then
  local function MFMessage()
    local mode = net.ReadInt(8)
    if mode == 1 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will die on a heart-attack, standart 30 seconds!")
    elseif mode == 2 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will burn in Hell, but the style takes 10 more seconds!")
    elseif mode == 3 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer will explode, but it takes 20 more seconds than normal!")
    elseif mode == 5 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"You have experienced the " ,Color(255,0,0) ,"fate " ,Color(250,250,250) ,"your victim chose." )
    elseif mode == 10 then
      chat.AddText("Mirror Fate: ", Color(250,250,250) ,"Your killer has shared your " ,Color(255,0,0), "fate." )
    end
    chat.PlaySound()
  end
  net.Receive("MFMessage", MFMessage)
end
