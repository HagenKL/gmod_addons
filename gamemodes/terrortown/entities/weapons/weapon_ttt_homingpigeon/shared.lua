if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddFile( "materials/VGUI/ttt/icon_homingpigeon.png" )
  util.AddNetworkString("DropPigeon")
  util.AddNetworkString("RemovePigeon")
  util.AddNetworkString("SendTargetPigeon")
  resource.AddWorkshop("620936792")
end

SWEP.HoldType = "grenade"

if CLIENT then

  SWEP.PrintName = "Homing Pigeon"
  SWEP.Slot = 6

  SWEP.ViewModelFlip = false

  SWEP.EquipMenuData = {
    type = "item_weapon",
    desc = "A flying pigeon that seeks out a target."
  };

  SWEP.Icon = "VGUI/ttt/icon_homingpigeon.png"

  function SWEP:ViewModelDrawn()
    local VM = LocalPlayer():GetViewModel()
    if( IsValid( VM ) )then
      if( !IsValid( self.Pigeon ) ) then
        self.Pigeon = ents.CreateClientProp( "models/pigeon.mdl" )
        local I = 0
        while( I <= VM:GetBoneCount() )do
          VM:ManipulateBoneScale( I, Vector( 0.005, 0.005, 0.005 ) )
          I = I + 1
        end
      elseif( IsValid( self.Pigeon ) ) then
        local VM = self.Owner:GetViewModel()
        local BP, BA = VM:GetBonePosition( VM:LookupBone( "ValveBiped.Bip01_R_Hand" ) )
        BP = BP - BA:Forward() * 3 - BA:Up() * 6 - BA:Right() * 4
        self.Pigeon:SetPos( BP )
        BA:RotateAroundAxis( BA:Right(), -60 )
        BA:RotateAroundAxis( BA:Forward(), 180 )
        self.Pigeon:SetAngles( BA )
        self.Pigeon:SetParent( VM )
      end
    end
  end
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 60
SWEP.DrawCrosshair = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 1
SWEP.Primary.Ammo = "AR2AltFire"

SWEP.Kind = WEAPON_EQUIP1
SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy
SWEP.LimitedStock = true

if SERVER then
  net.Receive("SendTargetPigeon", function(len,ply)
      if ply:GetActiveWeapon():GetClass() == "weapon_ttt_homingpigeon" then
        local TargetPly = net.ReadEntity()
        local wep = net.ReadEntity()
        if ( IsValid( ply ) and IsValid( TargetPly ) ) then
          local Pigeon = ents.Create( "ttt_pigeon" )
          if !IsValid( Pigeon ) then return end
          Pigeon:SetPos( ply:GetShootPos() + ply:GetAimVector() * 5)
          Pigeon:SetAngles( ( TargetPly:GetShootPos() - ply:GetShootPos() ):Angle() )
          Pigeon.Target = TargetPly
          Pigeon:Spawn()
          Pigeon:SetOwner( ply )
          wep:Remove()
          ply:StripWeapon( "weapon_ttt_homingpigeon" )
          wep:SetNextPrimaryFire( CurTime() + wep.Primary.Delay )
        end
      end
    end)
    function SWEP:PrimaryAttack()
      return
    end
end

function SWEP:SecondaryAttack()
  return
end

function SWEP:Equip()
  self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
  net.Start("RemovePigeon")
  net.WriteEntity(self.Weapon)
  net.Broadcast()
end

function SWEP:OnRemove()
  if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
    RunConsoleCommand("lastinv")
  end
  if SERVER then
    net.Start("RemovePigeon")
    net.WriteEntity(self.Weapon)
    net.Broadcast()
  end
end

function SWEP:Deploy()
  return true
end

function SWEP:DrawWorldModel()
  if not CLIENT then return end

  if IsValid( self.Owner ) and not( IsValid( self.PigeonModel ) ) then
    self.PigeonModel = ents.CreateClientProp( "models/pigeon.mdl" )
    local Pos, Ang = self.Owner:GetBonePosition( self.Owner:LookupBone( "ValveBiped.Bip01_R_Hand" ) )
    self.PigeonModel:SetPos( Pos )
    self.PigeonModel:SetAngles( Ang )
    //self.PigeonModel:AddEffects( EF_BONEMERGE )
    self.PigeonModel:SetParent( self.Owner )
  end

  if( IsValid( self.PigeonModel ) and IsValid( self.Owner ) ) then
    local Pos, Ang = self.Owner:GetBonePosition( self.Owner:LookupBone( "ValveBiped.Bip01_R_Hand" ) )
    Ang:RotateAroundAxis( Ang:Forward(), -100 )
    self.PigeonModel:SetPos( Pos )
    self.PigeonModel:SetAngles( Ang )
  end
end

function SWEP:Holster()
  RemovePigeonModel( self.Weapon )
  return true
end

function SWEP:OnDrop()
  net.Start("DropPigeon")
  net.WriteEntity(self.Weapon)
  net.Broadcast()
end

if CLIENT then

  function SWEP:PrimaryAttack()
    if !self:CanPrimaryAttack() then return end
    local TargetPly = self.Owner:GetEyeTrace().Entity
    if IsValid(TargetPly) and TargetPly:IsPlayer() and TargetPly:IsTerror() then
      net.Start("SendTargetPigeon")
      net.WriteEntity(TargetPly)
      net.WriteEntity(self)
      net.SendToServer()
    else
      self:SetNextPrimaryFire(CurTime() + 0.1)
    end
  end

  net.Receive("DropPigeon", function()
      local E = net.ReadEntity()
      if( !IsValid( E ) ) then return end
      RemovePigeonModel( E )
      E.PigeonModel = ents.CreateClientProp( "models/pigeon.mdl" )
      if( IsValid( E.PigeonModel ) ) then
        E.PigeonModel:SetPos( E:GetPos() - E:GetUp() * 7 )
        E.PigeonModel:SetParent( E )
      end
    end )

  net.Receive("RemovePigeon", function()
      local Ent = net.ReadEntity()
      if !IsValid(Ent) then return end
      RemovePigeonModel( Ent )
    end )
end

function RemovePigeonModel( Ent )
  if( CLIENT ) then
    local VM = LocalPlayer():GetViewModel()
    if( IsValid( VM ) and VM.GetBoneCount and VM:GetBoneCount() and VM:GetBoneCount() > 0 ) then
      local I = 0
      while( I <= VM:GetBoneCount() ) do
        VM:ManipulateBoneScale( I, Vector( 1,1,1 ) )
        I = I + 1
      end
    end
  end
  if( !IsValid( Ent ) ) then return end

  if( Ent.PigeonModel and IsValid( Ent.PigeonModel ) ) then
    Ent.PigeonModel:Remove()
    Ent.PigeonModel = nil
  end

  if( Ent.Pigeon and IsValid( Ent.Pigeon ) ) then
    Ent.Pigeon:Remove()
  end
end

if( CLIENT ) then
  hook.Add( "Think", "EnforceViewModelSize", function()
      local VM = LocalPlayer():GetViewModel()
      if( IsValid( VM ) and VM.GetBoneCount and VM:GetBoneCount() and VM:GetBoneCount() > 0 and VM:GetModel() != "models/weapons/v_grenade.mdl" and VM:GetManipulateBoneScale( 1 ) == Vector( 0.005, 0.005, 0.005 ) ) then
        local I = 0
        while( I < VM:GetBoneCount() ) do
          VM:ManipulateBoneScale( I, Vector( 1, 1, 1 ) )
          I = I + 1
        end
      end
    end )
end
