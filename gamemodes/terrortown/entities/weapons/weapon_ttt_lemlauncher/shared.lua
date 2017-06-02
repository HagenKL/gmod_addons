if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	resource.AddFile( "materials/lemnade/lemlauncher1.png" )
end

if CLIENT then

   SWEP.PrintName    = "Lemnade Launcher"
   SWEP.Slot         = 7

   SWEP.ViewModelFOV  = 55
   SWEP.ViewModelFlip = false

   SWEP.Icon = "materials/lemnade/lemlauncher1.png"
   SWEP.EquipMenuData = {
   type = "Weapon",
   desc = "Left-click to shoot a lemon, \nRight-Click to play Cave Johnson´s voice."
};
end



SWEP.Base				= "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.HoldType = "ar2"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = { ROLE_DETECTIVE }
SWEP.LimitedStock = true
-----------------------------------------------

------------Models---------------------------
SWEP.ViewModel      = "models/weapons/c_rpg.mdl"
SWEP.WorldModel   = "models/weapons/w_rocket_launcher.mdl"
-----------------------------------------------

-------------Primary Fire Attributes----------------------------------------
SWEP.Primary.TakeAmmo       = 1
SWEP.Primary.Delay			= 1  --In seconds
SWEP.Primary.Recoil			= 2		--Gun Kick
SWEP.Primary.Damage			= 0	--Damage per Bullet
SWEP.Primary.NumShots		= 1		--Number of shots per one fire
SWEP.Primary.Cone			= 0 	--Bullet Spread
SWEP.Primary.ClipSize		= 1	--Use "-1 if there are no clips"
SWEP.Primary.DefaultClip	= 1	--Number of shots in next clip
SWEP.Primary.Automatic   	= true	--Pistol fire (true) or SMG fire (true)
SWEP.Primary.Ammo         	= "RPG_Round"	--Ammo Type
SWEP.HoldType			= "rpg"
SWEP.AmmoEnt = "nil"
-------------End Primary Fire Attributes------------------------------------

 SWEP.UseHands = true
 SWEP.IconLetter  = "x"
 SWEP.WepSelectIcon      = Material("vgui/ttt/weapon_lemlauncher.vmt")
 SWEP.BounceWeaponIcon   = false

-------------Secondary Fire Attributes-------------------------------------
SWEP.Secondary.Delay		= 0.1
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 0
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic   	= true
SWEP.Secondary.Ammo         = "none"


-------------Lemon Launcher local globals---------------------------------


function SWEP:Initialize()
	util.PrecacheSound("lemongrenade/-lemon.wav")
	util.PrecacheSound("lemongrenade/combustable-.wav")
	util.PrecacheSound("lemongrenade/Combustible.01.wav")
	util.PrecacheSound("lemongrenade/Combustible.02.wav")
	util.PrecacheSound("lemongrenade/Combustible.03.wav")
	util.PrecacheSound("lemongrenade/Combustible.04.wav")
	util.PrecacheSound("lemongrenade/Combustible.05.wav")
	util.PrecacheSound("lemongrenade/lemonadecombustible.wav")
	util.PrecacheSound("lemongrenade/ready_throw.wav")
	util.PrecacheSound("weapons/mortar/mortar_fire1.wav")
	self:SetWeaponHoldType( self.HoldType )
	if SERVER then
		timer.Simple(0.1, function() if (IsValid(self.Owner)) then self.Owner:GiveAmmo(1, "RPG_Round", true) end end)
	end
end

function SWEP:Deploy()
   self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
   return self.BaseClass.Deploy(self)
end

function cbmSprite( Entity, fx, color, spritePath, scale, transity)
	local Sprite = ents.Create("env_sprite");
	Sprite:SetPos( Entity:GetPos() );
	Sprite:SetKeyValue( "renderfx", fx )
	Sprite:SetKeyValue( "model", spritePath)
	Sprite:SetKeyValue( "scale", scale)
	Sprite:SetKeyValue( "spawnflags", "1")
	Sprite:SetKeyValue( "angles", "0 0 0")
	Sprite:SetKeyValue( "rendermode", "3")
	Sprite:SetKeyValue( "renderamt", transity)
	Sprite:SetKeyValue( "rendercolor", color )
	Sprite:SetName( "Hds46_addon_lemonade_lemsprite")

	Sprite:Spawn()
	Sprite:Activate()
	Sprite:SetParent( Entity )
end

function cbmLight( Entity)
	local light = ents.Create("light_dynamic")
	light:SetPos( Entity:GetPos() )
	light:Spawn()
	light:SetKeyValue("_light","255 255 25")
	light:SetKeyValue("distance",150)
	light:SetParent( Entity )
end

function SWEP:PrimaryAttack(data)
	if (not self:CanPrimaryAttack()) then return end

	self:EmitSound( "lemongrenade/LemonadeCombustible.wav" )
	self:EmitSound("weapons/mortar/mortar_fire1.wav")
	self:SetNextPrimaryFire(CurTime() + 3)
	self:SetNextSecondaryFire(CurTime() + 3.0)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:SetAnimation( PLAYER_ATTACK1 )

	self:TakePrimaryAmmo(self.Primary.TakeAmmo)
	self:MuzzleFlash()
	local rnda = self.Primary.Recoil * -1
	local rndb = self.Primary.Recoil * math.random(-1, 1)
	self.Owner:ViewPunch( Angle( rnda,rndb,rnda ) )
	local effectdata = EffectData()
	effectdata:SetOrigin( self.Owner:GetPos() )
	util.Effect( "Dlemlight", effectdata )

	local p = self.Owner
	local vec1 = p:GetAimVector()
	local forw = self:GetOwner():EyeAngles():Forward()

	if CLIENT then return end --This was added

	local launch = ents.Create("ttt_lemon_proj")
	launch:SetAngles(Angle(0,90,0))-- Angle(0,90,0))
	launch:SetPos(self.Owner:GetShootPos())
	launch:SetOwner(self.Owner)
	launch:SetPhysicsAttacker(self.Owner)
	launch:Spawn()

	util.SpriteTrail(launch, 0, Color(255,255,0), false, 15, 1, 0.5, 1/(15+1)*0.5, "trails/plasma.vmt")
	cbmSprite( launch, "14", "255 225 25", "sprites/glow03.vmt", "1", "255")
	cbmLight( launch )
	local phys = launch:GetPhysicsObject()
	phys:SetVelocity( forw * 3000 )
	phys:AddAngleVelocity(Vector(90,0,0))

	timer.Simple(0.5, function() if IsValid(self.Owner) then if self.Owner:Alive() then self:Reload() end end end )
end

function SWEP:SecondaryAttack()
	self:EmitSound( "lemongrenade/combustible.0" .. math.random( 1, 5 ) .. ".wav")
	self.Weapon:SetNextSecondaryFire( CurTime() + 3 )
end

if CLIENT then
	local EFFECT={}

	function EFFECT:Init( data )
		self.Origin = data:GetOrigin()

		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			local r, g, b, a = self:GetColor()
			dlight.Pos = self:GetPos()
			dlight.r = 255
			dlight.g = 255
			dlight.b = 10
			dlight.Brightness = 0.9
			dlight.Size = 150
			dlight.Decay = 1000
			dlight.DieTime = CurTime() + 0.05
	        dlight.Style = 0
		end
	end

	function EFFECT:Think()
		return false
	end

	function EFFECT:Render()
	end

	effects.Register(EFFECT, "Dlemlight" )
end
