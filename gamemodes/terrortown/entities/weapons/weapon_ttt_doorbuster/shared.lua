local detectiveEnabled = CreateConVar("ttt_doorbuster_detective", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Detectives be able to buy the Door Buster?")
local traitorEnabled = CreateConVar("ttt_doorbuster_traitor", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Traitors be able to buy the Door Buster?")

if (SERVER) then
	resource.AddWorkshop("621565420")
	AddCSLuaFile( "shared.lua" )
	AddCSLuaFile( "gamemodes/terrortown/entities/entities/entity_doorbuster/cl_init.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
end

if ( CLIENT ) then

	SWEP.DrawAmmo			= true
	SWEP.ViewModelFOV		= 64
	SWEP.ViewModelFlip		= false
	SWEP.CSMuzzleFlashes	= false


	SWEP.PrintName			= "Door Buster"
	SWEP.Author				= "dante vi almark"
	SWEP.Slot				= 6
	SWEP.SlotPos			= 11
   SWEP.Icon = "VGUI/ttt/icon_doorbust"
   SWEP.EquipMenuData = {
   type = "Weapon",
   desc = "Placeable on doors. \nThe Door will explode when opened \nand kill everyone on its way."
};
end
local ValidDoors = {"prop_door_rotating", "func_door_rotating"}

SWEP.Author			= "-Kenny-"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= "Place on Door"

//GeneralSettings\\
SWEP.Base				= "weapon_tttbase"
SWEP.AutoSpawnable = !detectiveEnabled:GetBool() and !traitorEnabled:GetBool()
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = !detectiveEnabled:GetBool() and !traitorEnabled:GetBool() and WEAPON_NADE or WEAPON_EQUIP1
SWEP.HoldType			= "slam"


SWEP.Spawnable			= false
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/v_c4.mdl"
SWEP.WorldModel			= "models/weapons/w_c4.mdl"


SWEP.Primary.Recoil				= 0
SWEP.Primary.Damage				= -1
SWEP.Primary.NumShots			= 1
SWEP.Primary.Cone			  	= 0
SWEP.Primary.Delay				= 1
SWEP.Primary.ClipSize			= 1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo					= "slam"
SWEP.CanBuy = {}
if (detectiveEnabled:GetBool()) then
	table.insert(SWEP.CanBuy, ROLE_DETECTIVE)
end
if (traitorEnabled:GetBool()) then
	table.insert(SWEP.CanBuy, ROLE_TRAITOR)
end
SWEP.LimitedStock = false
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Delay = 2

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	util.PrecacheSound("weapons/gamefreak/beep.wav")
	util.PrecacheSound("weapons/c4/c4_plant.wav")
	util.PrecacheSound("weapons/gamefreak/johncena.wav")
	self:SetMaterial("c4_green/w/c4_green")
end

function SWEP:OnRemove()
  if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
    RunConsoleCommand("lastinv")
  end
end

/*function SWEP:Deploy()
	if SERVER then self:CallOnClient("Deploy","") end
	self.Owner:GetViewModel():SetSubMaterial(1,"c4_green/v/c4_green")
return true
end*/

/*function SWEP:PreDrop()
	if IsValid(self.Owner) then self.Owner:GetViewModel():SetSubMaterial(1,"") end
	return true
end*/


function SWEP:Plant()


    if !SERVER then return end

    local tr = self.Owner:GetEyeTrace()
    local angle = tr.HitNormal:Angle()
    local bomb = ents.Create("entity_doorbuster")
    local ent = tr.Entity


    ent.DoorBusterEnt = bomb
    bomb:SetPos(tr.HitPos)
    bomb:SetAngles(angle+Angle(-90,0,180))
    bomb:Spawn()
    bomb:SetOwner(self.Owner)
    bomb:SetParent(ent)
    bomb:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    bomb:EmitSound("weapons/c4/c4_plant.wav")
    --bomb:EmitSound("weapons/gamefreak/beep.wav")
    self:Remove()
end


function SWEP:CanPrimaryAttack()
  local tr = self.Owner:GetEyeTrace()
    local hitpos = tr.HitPos
    local dist = self.Owner:GetShootPos():Distance(hitpos)
    local InWorld = true;
    if SERVER then
        InWorld = util.IsInWorld(tr.HitNormal*-50 + tr.HitPos)
    end
    return tr.Entity and table.HasValue(ValidDoors,tr.Entity:GetClass()) and dist<60 and self.Weapon:Clip1() > 0 and InWorld
end


function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	self:Plant()
end
