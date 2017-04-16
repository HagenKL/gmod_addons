if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddFile( "materials/vgui/ttt/icon_timer.vmt" )
  resource.AddWorkshop("611873052")

  local PLAYER = FindMetaTable("Player")
  util.AddNetworkString( "ColoredMessage" )
  function BroadcastMsg(...)
    local args = {...}
    net.Start("ColoredMessage")
    net.WriteTable(args)
    net.Broadcast()
  end

  function PLAYER:PlayerMsg(...)
    local args = {...}
    net.Start("ColoredMessage")
    net.WriteTable(args)
    net.Send(self)
  end
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
  net.Receive("ColoredMessage",function(len)
      local msg = net.ReadTable()
      chat.AddText(unpack(msg))
      chat.PlaySound()
    end)
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
  function SWEP:Initialize()
    if IsValid(self.Owner) then
      self.Owner.fatemode = 1
      self.Owner.fatetimemode = 30
    end
  end
  function SWEP:PrimaryAttack()
    local ply = self.Owner
    ply.fatetimemode = ply.fatetimemode + 10
    if ply.fatetimemode >= 100 then
      ply.fatetimemode = 30
    end
    ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"The Fate will now take " .. ply.fatetimemode .. " seconds!")
  end
  function SWEP:SecondaryAttack()
    local ply = self.Owner
    ply.fatemode = ply.fatemode + 1
    if ply.fatemode >= 4 then
      ply.fatemode = 1
    end
    if ply.fatemode == 1 then
      ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer will die on a heart-attack!")
    elseif ply.fatemode == 2 then
      ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer will explode!")
    elseif ply.fatemode == 3 then
      ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer will burn in Hell!")
    end
  end
  function KillTheKillerMirrorfate( victim, killer, damageinfo )
    if IsValid(killer) and IsValid(victim) then
      if !killer.DyeOnFate and victim:HasWeapon("weapon_ttt_mirrorfate") and !killer:HasWeapon("weapon_ttt_mirrorfate") then
        killer.DyeOnFate = true
        TTTMirrorfateKillHim(victim, killer)
      end
    end
  end
  function TTTMirrorfateKillHim(victim, killer)
    timer.Create( "MirrorFatekill" .. killer:EntIndex(), victim.fatetimemode or 30 , 1, function()
        if IsValid(killer) then
          if killer:IsTerror() and killer.DyeOnFate then
            if victim.fatemode == 1 then
              local dmginfo = DamageInfo()
              dmginfo:SetDamage(10000)
              dmginfo:SetAttacker(victim)
              dmginfo:SetDamageType(DMG_GENERIC)
              killer:TakeDamageInfo(dmginfo)
            elseif victim.fatemode == 2 then
              local effectdata = EffectData()
              killer:EmitSound( Sound ("ambient/explosions/explode_4.wav") )
              util.BlastDamage( victim, victim, killer:GetPos() , 200 , 1000 )
              effectdata:SetStart( killer:GetPos() + Vector(0,0,10) )
              effectdata:SetOrigin( killer:GetPos() + Vector(0,0,10) )
              effectdata:SetScale( 1 )
              util.Effect( "HelicopterMegaBomb", effectdata )
            elseif victim.fatemode == 3 then
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
            else
              local dmginfo = DamageInfo()
              dmginfo:SetDamage(10000)
              dmginfo:SetAttacker(victim)
              dmginfo:SetDamageType(DMG_GENERIC)
              killer:TakeDamageInfo(dmginfo)
            end
            killer:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"You have experienced the " ,Color(255,0,0) ,"fate " ,Color(250,250,250) ,"your victim choose." )
            victim:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer has shared your " ,Color(255,0,0), "fate." )
          elseif IsValid(victim) and (!IsValid(killer) or !killer:IsTerror()) then
            victim:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer is already dead!")
          end
        end
      end )
  end
  hook.Add( "DoPlayerDeath" , "MirrorfateKillhim" , KillTheKillerMirrorfate )

  local function ResetMirrorFate(ply)
    timer.Remove("MirrorFatekill" .. ply:EntIndex())
    timer.Remove("BurnInHellMirrorfate" .. ply:EntIndex())
    ply.fatemode = 1
    ply.fatetimemode = 30
    ply.DyeOnFate = false
  end

  hook.Add("PlayerSpawn", "ResetMirrorFate", function(ply)
    ResetMirrorFate(ply)
  end)
  hook.Add("TTTPrepareRound","ResetMirrorFate", function()
      for key,ply in pairs(player.GetAll()) do
        ResetMirrorFate(ply)
      end
    end)
end
