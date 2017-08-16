//GeneralSettings\\
SWEP.Base = "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.HoldType = "pistol"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = WEAPON_EQUIP1

//Serverside\\
if SERVER then
	AddCSLuaFile( "shared.lua" )
	resource.AddFile("materials/VGUI/ttt/icon_peacekeeper.vmt")
	resource.AddWorkshop("788891000")
	util.AddNetworkString( "HNHighNoonSound" )
	util.AddNetworkString( "HNDrawSound" )
	util.AddNetworkString( "HNStartSound" )
	util.AddNetworkString("HighNoonBullet")
end

//Clientside\\
if CLIENT then
	SWEP.PrintName = "Peacekeeper"
	SWEP.Slot = 6
	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false
	SWEP.Icon = "VGUI/ttt/icon_peacekeeper"

	SWEP.EquipMenuData = {
		type = "weapon",
		desc = "Its High Noon, I guess you know what to do. \nYou can only use it once. \nUse Right Click to taunt. "
	}

end

//Damage\\
SWEP.Primary.Delay = 0.145
SWEP.Primary.Recoil = 0.1
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 1
SWEP.Primary.Damage = 1000
SWEP.Primary.Cone = 0.0001
SWEP.Primary.ClipSize = 6
SWEP.Primary.ClipMax = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Force = 1000
SWEP.AmmoEnt = ""
SWEP.Secondary.Automatic = false

//Verschiedenes\\
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.UseHands = true
SWEP.HeadshotMultiplier = 1
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.LimitedStock = true

//Sounds/Models\\
SWEP.ViewModel = "models/weapons/peacekeeper/v_mccree_peacekeeper.mdl"
SWEP.WorldModel = "models/weapons/peacekeeper/w_mccree_peacekeeper.mdl"
SWEP.Weight = 5
SWEP.Primary.Sound = Sound( "weapons/peacekeeper/fire.wav" )

function SWEP:OnRemove()
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
		RunConsoleCommand("lastinv")
	end
end

function SWEP:Initialize()
	util.PrecacheSound("weapons/peacekeeper/highnoon.wav")
	util.PrecacheSound("weapons/peacekeeper/ult1.wav")
	util.PrecacheSound("weapons/peacekeeper/ult2.wav")
	util.PrecacheSound("weapons/peacekeeper/ult3.wav")
	util.PrecacheSound("weapons/peacekeeper/spawn1.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt1.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt2.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt3.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt4.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt5.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt6.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt7.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt8.wav")
	util.PrecacheSound("weapons/peacekeeper/taunt9.wav")
end

local function IsInFOV( ply, target )
	local targetPos = target:Crouching() and target:GetPos() + Vector(0,0,25) or target:GetPos() + Vector(0,0,50)
	local inFOV = ply:GetAimVector():Dot(((targetPos) - ply:GetShootPos()):GetNormalized()) > 0.52
	local los = ply:IsLineOfSightClear(targetPos)
	if inFOV and los then
		local kmins = Vector(1,1,1) * -5
		local kmaxs = Vector(1,1,1) * 5
		local tr = util.TraceHull({
			start = ply:GetShootPos(),
			endpos = targetPos,
			filter = function(ent)
				if (ent:IsPlayer() and ent != target) or ent:IsWeapon() or string.sub( ent:GetClass(), 1, 5 ) == "item_" then
					return false
				end
				return true
			end,
			mask = MASK_SHOT_HULL,
			mins=kmins, 
			maxs=kmaxs
		})
		if !tr.Entity:IsPlayer() then
			local tr = util.TraceLine({
				start = ply:GetShootPos(),
				endpos = targetPos,
				filter = function(ent)
					if (ent:IsPlayer() and ent != target) or ent:IsWeapon() or string.sub( ent:GetClass(), 1, 5 ) == "item_" then
						return false
					end
					return true
				end,
				mask = MASK_SHOT_HULL
			})
		end
		return tr.Entity == target
	end
	return false
end

function SWEP:SetupDataTables()
	self:NetworkVar("String","0","HighNoon")
	return self.BaseClass.SetupDataTables(self)
end

if SERVER then


	function SWEP:PrimaryAttack()
		if self:GetHighNoon() == "charging" and #self.Owner.highnoontargets > 0 then
			self:FireHighNoon()
		elseif (self:GetHighNoon() == "none" or !self:GetHighNoon()) and self:CanPrimaryAttack() then
			self:StartHighNoon()
		end
	end

	function SWEP:SecondaryAttack()
		if self:GetHighNoon() == "charging" then
			self:EndHighNoon()
		elseif !self:HighNoonActive() then
			self:SetNextSecondaryFire(CurTime() + 3)
			self.Owner:EmitSound( Sound("weapons/peacekeeper/taunt" .. math.random(1,9) .. ".wav"), 100, 100, 1, CHAN_AUTO)
		end
	end

	function SWEP:Think()
		local owner = self.Owner
		if self:GetHighNoon() == "starting" and self.HighNoonStart <= CurTime() then
			self.HighNoonEnd = CurTime() + 7
			self:SetHighNoon("charging")
			net.Start("HNHighNoonSound")
			net.Broadcast()
		end
		if self:GetHighNoon() == "charging" and self.HighNoonEnd <= CurTime() then
			self:EndHighNoon()
		end
		if self:GetHighNoon() == "firing" and self.NextFire <= CurTime() then
			if #owner.highnoontargets > 0 or self:Clip1() == 0 then
				self.NextFire = CurTime() + 0.2
				self:FireHighNoonBullet()
			else
				self:EndHighNoon()
				owner:EmitSound(Sound("weapons/peacekeeper/ult" .. math.random(1, 3) .. ".wav"), 100, 100, 1, CHAN_AUTO)
			end
		end
		self.hntimer = self.hntimer or 0
		if self:GetHighNoon() == "charging" and self.hntimer <= CurTime() then
			self.hntimer = CurTime() + 0.06
			for k,ply in pairs(util.GetAlivePlayers()) do
				if ply != owner then
					local wasinfov = ply:GetNWBool("HighNoonFOV" .. self:EntIndex())
					if wasinfov and !IsInFOV(owner, ply) then
						ply:SetNWBool("HighNoonFOV" .. self:EntIndex(), false)
						table.RemoveByValue(owner.highnoontargets, ply)
						continue
					end
					if wasinfov and IsInFOV(owner, ply) then
						ply:SetNWInt("HighNoonCharged" .. self:EntIndex(), ply:GetNWInt("HighNoonCharged" .. self:EntIndex(),0) + 4)
					end
					if #owner.highnoontargets >= 6 then
						continue
					end
					if !wasinfov and IsInFOV(owner, ply) then
						if (owner:GetRole() == ROLE_INNOCENT or owner:GetRole() == ROLE_DETECTIVE or (owner.GetGood and owner:GetGood())) or (owner:IsTraitor() and !ply:IsTraitor() and ((ply.IsEvil and !ply:IsEvil()) or !ply.IsEvil)) or (owner.IsEvil and owner:IsEvil() and !ply:IsEvil()) or (owner.IsNeutral and owner:IsNeutral() and !ply:IsNeutral())  then
							table.insert(owner.highnoontargets, ply)
							ply:SetNWBool("HighNoonFOV" .. self:EntIndex(), true)
						end
					end
				end
			end
		end
		return self.BaseClass.Think(self)
	end

	function SWEP:StartHighNoon()
		local owner = self.Owner
		self:SetHoldType("normal")
		self:SetHighNoon("starting")
		self.HighNoonStart = CurTime() + 1
		self:SendWeaponAnim(ACT_VM_IDLE_3)
		net.Start("HNStartSound")
		net.Broadcast()
		if IsValid(owner) then
			owner.HighNoonTempJump = owner:GetJumpPower()
			owner:SetJumpPower(0)
		end
	end

	function SWEP:FireHighNoon()
		local owner = self.Owner
		self:SetHoldType("revolver")
		self:SetHighNoon("firing")
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self.NextFire = CurTime() + 0.1
		if IsValid(owner) then
			owner:Freeze(true)
		end
		net.Start("HNDrawSound")
		net.Broadcast()
	end

	function SWEP:FireHighNoonBullet()
		local owner = self.Owner

		
		local ply = owner.highnoontargets[math.random(1,#owner.highnoontargets)]
		local targetPos = ply:Crouching() and ply:GetPos() + Vector(0,0,25) or ply:GetPos() + Vector(0,0,50)
		local dir = (targetPos - owner:GetShootPos() ):GetNormalized()

		net.Start("HighNoonBullet")
		net.WriteInt(ply:GetNWInt("HighNoonCharged" .. self:EntIndex()),8)
		net.WriteVector(dir)
		net.Send(owner)

		local bullet = {}
		bullet.Num    = 1
		bullet.Src    = owner:GetShootPos()
		bullet.Dir    = dir
		bullet.Spread = Vector(0.001,0.001,0)
		bullet.Force  = 10
		bullet.Damage = ply:GetNWInt("HighNoonCharged" .. self:EntIndex())
		bullet.Callback = function(attacker,tr,dmginfo)
			if !tr.Entity:IsPlayer() then
				ply.DelayedDamage = true
			end
		end

		self.Owner:EmitSound(self.Primary.Sound, 511, 100, 1, CHAN_AUTO)
		self.Owner:FireBullets( bullet )
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

		if ply:IsTerror() and ply.DelayedDamage then
			local dmg = DamageInfo()
			dmg:SetDamage(ply:GetNWInt("HighNoonCharged" .. self:EntIndex()))
			dmg:SetInflictor(self)
			dmg:SetAttacker(self.Owner)
			dmg:SetDamagePosition(ply:GetPos())
			ply:TakeDamageInfo(dmg)
		end

		ply.DelayedDamge = false

		timer.Simple(0.08, function() if IsValid(self) then self:SendWeaponAnim(ACT_VM_IDLE_4) end end)

		table.RemoveByValue(owner.highnoontargets, ply)
	end

	function SWEP:EndHighNoon()
		local owner = self.Owner
		self:SetHoldType("pistol")
		self:SetHighNoon("none")
		if IsValid(owner) then
			owner:Freeze(false)
			owner:SetJumpPower(owner.HighNoonTempJump)
			owner.HighNoonTempJump = nil
		end
		self:ResetPlayers()
		self:SendWeaponAnim(ACT_VM_IDLE_2)
		self:SetClip1(0)
	end

	function SWEP:ResetPlayers()
		for k,ply in pairs(player.GetAll()) do
			ply:SetNWBool("HighNoonFOV" .. self:EntIndex(), false)
			ply:SetNWInt("HighNoonCharged" .. self:EntIndex(), 0)
		end
	end

	function SWEP:Deploy()
		self:ResetPlayers()
		self:SetHighNoon("none")
		self.Owner.highnoontargets = {}
		return self.BaseClass.Deploy(self)
	end

	function SWEP:PreDrop()
		if self:HighNoonActive() then
			self:EndHighNoon()
			self:SetClip1(0)
		end
		return self.BaseClass.PreDrop(self)
	end

	function SWEP:Reload() end

	local function HighNoonSpeed(ply)
		local w = ply:GetActiveWeapon()
		if w and IsValid(w) and w:GetClass() == "weapon_ttt_peacekeeper" and w:HighNoonActive() then
			return 0.2
		end
	end

	local function HighNoonDamage(ply, hitgroup, dmginfo)
		local wep = util.WeaponFromDamage(dmginfo)
		if wep and wep:GetClass() == "weapon_ttt_peacekeeper" then
			--ply.DelayedDamage = false
			if ply:HasEquipmentItem(EQUIP_ARMOR) then
				dmginfo:ScaleDamage(1.43)
			end
			if (hitgroup == HITGROUP_LEFTARM or
           		hitgroup == HITGROUP_RIGHTARM or
           		hitgroup == HITGROUP_LEFTLEG or
           		hitgroup == HITGROUP_RIGHTLEG or
           		hitgroup == HITGROUP_GEAR ) then

				dmginfo:ScaleDamage(1.81)
			end
		end
	end

	local function ResetHighNoon()
		for k,v in pairs(player.GetAll()) do
			if v.HighNoonTempJump then
				v.HighNoonTempJump = nil
				v:SetJumpPower(160)
			end
		end
	end

	hook.Add("TTTPlayerSpeed", "HighnoonSpeed" , HighNoonSpeed)
	hook.Add("ScalePlayerDamage", "HighNoonDamage", HighNoonDamage)
	hook.Add("TTTPrepareRound", "ResetHighNoon", ResetHighNoon)

elseif CLIENT then

	function SWEP:PrimaryAttack() end
	function SWEP:SecondaryAttack() end
	function SWEP:Reload() end

	local Deadeyeicon = Material( "materials/VGUI/ttt/deadeye.png" )
	local function HighNoonHUD()
		local wep = LocalPlayer():GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_ttt_peacekeeper" and wep:GetHighNoon() == "charging" then
			for k,v in pairs(util.GetAlivePlayers()) do
				if v:IsTerror() and v:GetNWBool("HighNoonFOV" .. wep:EntIndex(), false) then
					local pos = (v:Crouching() and v:GetPos() + Vector(0,0,25) or v:GetPos() + Vector(0,0,50)):ToScreen()
					local charge = v:GetNWInt("HighNoonCharged" .. wep:EntIndex(),0)
					local health = v:Health()
					local radius = math.Clamp(math.Remap(health - charge, 0, health, 12, 150),12,150)
					surface.DrawCircle(pos.x, pos.y, radius, Color(255, 1, 1, 255))
					if radius <= 12 then
						surface.SetMaterial(Deadeyeicon)
						surface.DrawTexturedRect(pos.x - 10, pos.y - 10, 20, 20)
						if !v.LockedOn then
							v.LockedOn = true
							surface.PlaySound("weapons/peacekeeper/deadeyelockedon.wav")
						end
					end
				end
			end
		else
			for k,v in pairs(player.GetAll()) do
				if v.LockedOn then
					v.LockedOn = false
				end
			end
		end
	end

	local function HighNoonBullet()
		local damage = net.ReadInt(8)
		local dir = net.ReadVector()

		local bullet = {}
		bullet.Num    = 1
		bullet.Src    = LocalPlayer():GetShootPos()
		bullet.Dir    = dir
		bullet.Spread = Vector(0.001,0.001,0)
		bullet.Force  = 10
		bullet.Damage = damage

		LocalPlayer():FireBullets( bullet )

	end

	function BlackandWhiteHighNoon()
		local wep = LocalPlayer():GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_ttt_peacekeeper" and wep:HighNoonActive() then
			local tbl = {
				["$pp_colour_addr"] = 0,
				["$pp_colour_addg"] = 0,
				["$pp_colour_addb"] = 0,
				["$pp_colour_brightness"] = 0,
				["$pp_colour_contrast"] = 1,
				["$pp_colour_colour"] = 0,
				["$pp_colour_mulr"] = 0.1,
				["$pp_colour_mulg"] = 0.1,
				["$pp_colour_mulb"] = 0.1
			}

			DrawColorModify(tbl)
		end
	end


	hook.Add("RenderScreenspaceEffects", "BlackandWhiteHighNoon", BlackandWhiteHighNoon )
	hook.Add("HUDPaint", "TTTHighNoon", HighNoonHUD)
	net.Receive("HighNoonBullet", HighNoonBullet)

	net.Receive("HNStartSound", function()
			surface.PlaySound("weapons/peacekeeper/begin.wav")
		end)
	net.Receive("HNHighNoonSound", function()
			surface.PlaySound("weapons/peacekeeper/highnoon.wav")
		end)
	net.Receive("HNDrawSound", function()
			surface.PlaySound("weapons/peacekeeper/draw.wav")
		end)
end

function SWEP:HighNoonActive()
	return (self:GetHighNoon() == "charging" or self:GetHighNoon() == "firing" or self:GetHighNoon() == "starting")
end

function SWEP:Holster()
	if self:HighNoonActive() then
		return false
	end
	return self.BaseClass.Holster(self)
end
