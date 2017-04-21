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
	util.AddNetworkString( "HNEndSound" )
	util.AddNetworkString( "HNStartSound" )
	util.AddNetworkString( "HNOnLockSound" )
	util.AddNetworkString( "HNChat" )
	util.AddNetworkString( "HNFailed" )
end

//Clientside\\
if CLIENT then
	SWEP.PrintName = "The Peacekeeper"
	SWEP.Slot = 6
	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false
	SWEP.Icon = "VGUI/ttt/icon_peacekeeper"

	SWEP.EquipMenuData = {
		type = "weapon",
		desc = "Its High Noon, I guess you know what to do. \nYou can only use it once. \nUse Right Click to taunt. "
	}

	net.Receive("ColoredMessage", function(len)
			local msg = net.ReadTable()
			chat.AddText(unpack(msg))
			chat.PlaySound()
		end)
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
SWEP.HeadshotMultiplier = 0
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
	self.highnoonactive = false
	self.highnoonshooting = false
	self.canpressattackhighnoon = false
	self.highnoonshots = 0
	self.HNTarget = nil
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

local highnoontargets = {}
function SWEP:Think()
	if GetRoundState() == ROUND_ACTIVE then
		if self.highnoonover and !self.highnoonshooting then
			self:EndHighNoon()
		end

		table.Empty(highnoontargets)
		local owner = self.Owner
		for k, v in pairs(player.GetAll()) do
			if CLIENT and v:IsTerror() and owner:IsLineOfSightClear(v) and v != owner and !v:GetNWBool("highnoonhit") then
				local pos = v:LocalToWorld(v:OBBCenter()) + Vector(0, 0, 30)
				pos.x = math.Round(pos.x)
				pos.y = math.Round(pos.y)
				pos.z = math.Round(pos.z)
				v.highnooncirclepos = pos:ToScreen()
			end

			local pos = v:LocalToWorld(v:OBBCenter()) + Vector(0, 0, 30)
			v:SetNWBool("highnoonpositionscreen", IsInFOV(owner, pos))

			if v:IsTerror() and #highnoontargets < 6 and owner:IsLineOfSightClear(v) and v != owner and !v:GetNWBool("highnoonhit") and v:GetNWBool("highnoonpositionscreen") and ((isfunction(v.IsFakeDead) and !v:IsFakeDead()) or !isfunction(v.IsFakeDead)) then
				if owner:IsTraitor() and !v:IsTraitor() and !v:IsHunter() then
					table.insert(highnoontargets, v)
				elseif owner.IsHunter and owner:IsHunter() and !v:IsHunter() and !v:IsTraitor() then
					table.insert(highnoontargets, v)
				elseif owner:GetRole() == ROLE_DETECTIVE or owner:GetRole() == ROLE_INNOCENT then
					table.insert(highnoontargets, v)
				end
			end
		end

		self.HNTarget = highnoontargets[1]
	end
end

function IsInFOV( ply, targetVec )
	return ply:GetAimVector():Dot((targetVec - ply:GetPos()):GetNormalized()) > 0.64
end

function SWEP:Equip(ply)
	ResettinHighNoon(ply)
	self.highnoonactive = false
	self.highnoonshooting = false
end

function SWEP:Deploy()
	local ply = self.Owner
	if !IsValid(ply) or !IsValid(self) or self:GetClass() != "weapon_ttt_peacekeeper" then return end
	self:SendWeaponAnim(ACT_VM_DRAW)
	self.canusehighnoon = false
	self.highnoonactive = false
	self.highnoonshooting = false
	ResettinHighNoon(self.Owner)

	timer.Create("dontusehighnoontooearly" .. self.Owner:EntIndex(), 0.75, 1, function()
			self.canusehighnoon = true
		end)
end

function SWEP:Holster()
	if self.highnoonactive or self.highnoonshooting then
		return false
	else
		return true
	end
end

function SWEP:PreDrop()
	if IsValid(self.Owner) then
		if self.highnoonshooting or self.highnoonactive then
			self:SetClip1(0)
			self.Owner:Freeze(false)
			RessetinPlayers(self.Owner)
		else
			ResettinHighNoon(self.Owner)
		end
	end
end

function SWEP:OnDrop()
	self.highnoonactive = false
	self.highnoonshooting = false
	self:SetHoldType("pistol")
end

function SWEP:PrimaryAttack()
	if SERVER then
		for k, v in pairs(player.GetAll()) do
			if v != self.Owner and v:GetNWBool("ItsHighNoon") or v:GetNWBool("ItsHighNoonshooting") then
				net.Start("HNFailed")
				net.Send(self.Owner)

				return
			end
		end
	end
	if self.canusehighnoon and GetRoundState() == ROUND_ACTIVE then
		if self.canpressattackhighnoon and !self.highnoonshooting and !self.highnoonover and self.HNTarget != nil then
			timer.Remove("highnoondamage")
			self:HighNoon()
			self.canpressattackhighnoon = false
			self.Owner:Freeze(true)
			self:SetHoldType("revolver")
			timer.Remove("highnoonisover" .. self.Owner:EntIndex())
		elseif !self.highnoonactive and !self.canpressattackhighnoon and !self.highnoonshooting then
			local ply = self.Owner
			if !IsValid(ply) or !IsValid(self) or self:GetClass() != "weapon_ttt_peacekeeper" then return end
			if self:Clip1() <= 0 then return end
			self.Owner:SetNWBool("ItsHighNoon", true)
			self:SetHoldType("normal")
			self.Owner:SetNWInt("HighNoonTimeEnd", CurTime() + 7)

			for k, v in pairs(player.GetAll()) do
				v:SetNWFloat("HighnoonRadius", v:Health() + 10)
				v:SetNWFloat("HighnoonDamage", 1)
				v:SetNWBool("highnoonpositionscreen", false)

				timer.Create("MakeHighnoonsound" .. v:EntIndex(), 0.01, 0, function()
						if v:GetNWBool("IsHighnoonfinished") and SERVER then
							net.Start("HNOnLockSound")
							net.Send(ply)
							timer.Remove("MakeHighnoonsound" .. v:EntIndex())
						end
					end)
			end

			if SERVER then
				net.Start("HNStartSound")
				net.Broadcast()
			end
			self.highnoonactive = true
			self.canpressattackhighnoon = false
			self:SendWeaponAnim(ACT_VM_IDLE_3)
			self.Owner:SetNWBool("WhiteandBlackHighNoon", true)

			timer.Remove("canusehighnoonnow" .. self.Owner:EntIndex())
			timer.Remove("highnoonisover" .. self.Owner:EntIndex())

			timer.Create("canusehighnoonnow" .. self.Owner:EntIndex(), 1, 1, function()
					if self.Owner:GetNWBool("ItsHighNoon") then
						if IsValid(ply) and IsValid(self) and self:GetClass() == "weapon_ttt_peacekeeper" and ply:Alive() and SERVER then
							net.Start("HNHighNoonSound")
							net.Broadcast()
						end

						self.Owner:SetNWBool("HNBegin", true)
						self.canpressattackhighnoon = true
					end

					timer.Create("highnoondamage", 0.02, 0, function()
							for k, v in pairs(highnoontargets) do
								if v:IsTerror() and self.Owner:IsLineOfSightClear(v) and v != self.Owner and !v:GetNWBool("highnoonhit") then
									if v:GetNWFloat("HighnoonRadius") > 10 then
										v:SetNWFloat("HighnoonRadius", v:GetNWFloat("HighnoonRadius") - 1.5)
									elseif v:GetNWFloat("HighnoonRadius") <= 10 then
										v:SetNWFloat("HighnoonRadius", 7)
										v:SetNWBool("IsHighnoonfinished", true)
									end

									v:SetNWFloat("HighnoonDamage", v:GetNWFloat("HighnoonDamage") + 1.5)
								end
							end
						end)
				end)

			timer.Create("highnoonisover" .. self.Owner:EntIndex(), 6, 1, function()
					if self.Owner:GetNWBool("ItsHighNoon") then
						self.highnoonover = true
					end
				end)
		end
	end
end

function SWEP:HighNoon()
	local ply = self.Owner
	if !IsValid(ply) or !IsValid(self) or self:GetClass() != "weapon_ttt_peacekeeper" then return end
	if self:Clip1() <= 0 then return end
	self.highnoonactive = false
	ply:SetNWBool("ItsHighNoon", false)
	ply:SetNWBool("HNBegin", false)
	ply:SetNWBool("ItsHighNoonshooting", true)
	self.highnoonshooting = true
	self:SetHoldType("pistol")

	timer.Create("drawsound" .. ply:EntIndex(), 0.16, 1, function()
			if SERVER then
				net.Start("HNDrawSound")
				net.Broadcast()
			end
		end)

	timer.Create("highnoon" .. ply:EntIndex(), 0.15, 6, function()
			if !IsValid(ply) or !IsValid(self) or self:GetClass() != "weapon_ttt_peacekeeper" then return end
			local target = self.HNTarget
			if target != nil and target:IsPlayer() then
				self:EmitSound(self.Primary.Sound, 511, 100, 1, CHAN_AUTO)
				self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

				timer.Create("secondshootanimation" .. ply:EntIndex(), 0.06, 1, function()
						self:SendWeaponAnim(ACT_VM_IDLE_4)
					end)

				local dmg = DamageInfo()
				dmg:SetDamage(target:GetNWFloat("HighNoonDamage"))
				dmg:SetAttacker(ply)
				dmg:SetInflictor(self)
				dmg:SetDamagePosition(ply:GetPos())
				dmg:SetDamageType(DMG_BULLET)

				if SERVER then
					target:TakeDamageInfo(dmg)
				end

				target:SetNWBool("highnoonhit", true)
				table.remove(highnoontargets, 1)
				self:TakePrimaryAmmo(1)

				if self:Clip1() <= 0 or table.Count(highnoontargets) == 0 or GetRoundState() != ROUND_ACTIVE then
					timer.Create("ResetHighNoon", 0.5, 1, function()
							if IsValid(ply) and IsValid(self) and self:GetClass() == "weapon_ttt_peacekeeper" and ply:Alive() then
								self:EndHighNoon()
								ply:EmitSound(Sound("weapons/peacekeeper/ult" .. math.random(1, 3) .. ".wav"), 100, 100, 1, CHAN_AUTO)
							end
						end)

					return
				end
			else
				self:EndHighNoon()
			end
		end)
end

function SWEP:SecondaryAttack()
	if self.canpressattackhighnoon and !self.highnoonshooting then
		self:EndHighNoon()
	elseif !self.highnoonactive and !self.highnoonshooting and self.canusehighnoon then
		self:SetNextSecondaryFire(CurTime() + 3)
		self.canusehighnoon = false
		timer.Simple(0.5, function() self.canusehighnoon = true end)
		self.Owner:EmitSound( Sound("weapons/peacekeeper/taunt" .. math.random(1,9) .. ".wav"), 100, 100, 1, CHAN_AUTO)
	end
end

function SWEP:EndHighNoon()
	self:SetClip1(0)
	self.highnoonshooting = false
	self.highnoonactive = false
	self.highnoonover = false
	self.canpressattackhighnoon = false
	self:SendWeaponAnim(ACT_VM_IDLE_2)
	self:SetHoldType("pistol")
	RessetinPlayers(self.Owner)
	table.Empty(highnoontargets)
end

function RessetinPlayers(ply)
	ResettinHighNoon(ply)
	for k,v in pairs(player.GetAll()) do
		v:SetNWBool("highnoonhit", false)
		v:SetNWBool("IsHighnoonfinished", false)
		v:SetNWBool("highnoonpositionscreen", false)
		v:SetNWFloat("HighnoonRadius", 100 )
		v:SetNWFloat("HighnoonDamage", 1 )
	end
end

function ResettinHighNoon(ply)
	timer.Remove("Highnoonlockon" .. ply:EntIndex())
	timer.Remove("highnoon" .. ply:EntIndex())
	timer.Remove("highnoon1" .. ply:EntIndex())
	timer.Remove("dontusehighnoontooearly" .. ply:EntIndex())
	timer.Remove("Highnoonlockon" .. ply:EntIndex())
	timer.Remove("secondshootanimation" .. ply:EntIndex())
	timer.Remove("drawsound" .. ply:EntIndex())
	timer.Remove("canusehighnoonnow" .. ply:EntIndex())
	timer.Remove("highnoonisover" .. ply:EntIndex())
	timer.Remove("MakeHighnoonsound" .. ply:EntIndex())
	timer.Remove("highnoondamage")
	ply:SetNWBool("WhiteandBlackHighNoon", false)
	ply:SetNWBool("ItsHighNoon", false)
	ply:SetNWBool("ItsHighNoonshooting", false)
	ply:SetNWBool("HNBegin", false)
	ply:Freeze(false)
end

function ResettinHighNoon2()
	for k,v in pairs(player.GetAll()) do
		timer.Remove("Highnoonlockon" .. v:EntIndex())
		timer.Remove("highnoon" .. v:EntIndex())
		timer.Remove("highnoon1" .. v:EntIndex())
		timer.Remove("dontusehighnoontooearly" .. v:EntIndex())
		timer.Remove("Highnoonlockon" .. v:EntIndex())
		timer.Remove("secondshootanimation" .. v:EntIndex())
		timer.Remove("drawsound" .. v:EntIndex())
		timer.Remove("canusehighnoonnow" .. v:EntIndex())
		timer.Remove("highnoonisover" .. v:EntIndex())
		timer.Remove("MakeHighnoonsound" .. v:EntIndex())
		timer.Remove("highnoondamage")
		v:SetNWBool("WhiteandBlackHighNoon", false)
		v:SetNWBool("ItsHighNoon", false)
		v:SetNWBool("ItsHighNoonshooting", false)
		v:SetNWBool("IsHighnoonfinished", false)
		v:SetNWBool("highnoonpositionscreen", false)
		v:SetNWBool("highnoonhit", false)
		v:SetNWFloat("HighnoonRadius", 100 )
		v:SetNWFloat("HighnoonDamage", 1 )
		v:SetNWBool("HNBegin", false)
		v.highnoonpositionscreen = false
	end
end

hook.Add("TTTPlayerSpeed", "HighnoonSpeed" , function(ply)
		local w = ply:GetActiveWeapon()
		if w and IsValid(w) and w.highnoonactive and w:GetClass() == "weapon_ttt_peacekeeper" then
			return 0.2
		end
	end )

hook.Add("TTTPrepareRound", "HighNoonReset", ResettinHighNoon2)

hook.Add( "PlayerDeath", "Highnoondead", function(ply)
		ply:SetNWBool("WhiteandBlackHighNoon", false)
		ply:SetNWBool("ItsHighNoon", false)
		ply:SetNWBool("ItsHighNoonshooting", false)
		ply:SetNWBool("IsHighnoonfinished", false)
		ply:SetNWBool("highnoonpositionscreen", false)
		ply:SetNWBool("HNBegin", false)
		ply:Freeze(false)
		ply:SetNWBool("highnoonhit", false)
		ply:SetNWBool("IsHighnoonfinished", false)
		ply:SetNWBool("highnoonpositionscreen", false)
		ply:SetNWFloat("HighnoonRadius", 100 )
		ply:SetNWFloat("HighnoonDamage", 1 )
	end )

hook.Add("EntityTakeDamage", "HighNoonLife", function(target, dmg)
		if target:GetNWBool("highnoonpositionscreen") then
			local damage = dmg:GetDamage()
			target:SetNWFloat("HighnoonRadius", target:GetNWFloat("HighnoonRadius") - math.Round(damage) )
		end
	end )

if CLIENT then
	net.Receive("HNFailed", function()
			chat.AddText("Peacekeeper: ", COLOR_WHITE, "Well, it's high noon somewhere else in the world, you sadly can´t use your Highnoon now.")
			chat.PlaySound()
		end)

	net.Receive("HNChat", function()
			chat.AddText("Peacekeeper: ", Color(255,255,255), net.ReadEntity():Nick() .. ", the gunslinger, is searching for duellists!")
			chat.PlaySound()
		end)

	net.Receive("HNStartSound", function()
			surface.PlaySound("weapons/peacekeeper/begin.wav")
		end)
	net.Receive("HNHighNoonSound", function()
			surface.PlaySound("weapons/peacekeeper/highnoon.wav")
		end)
	net.Receive("HNDrawSound", function()
			surface.PlaySound("weapons/peacekeeper/draw.wav")
		end)
	net.Receive("HNOnLockSound", function()
			surface.PlaySound("weapons/peacekeeper/deadeyelockedon.wav")
		end)

	local Deadeyeicon = Material( "materials/VGUI/ttt/deadeye.png" )
	function MakeAHighNoonCircle()
		if LocalPlayer():GetNWBool("HNBegin") and LocalPlayer():Alive() and GetRoundState() == ROUND_ACTIVE and LocalPlayer():IsTerror() then
			for k, v in pairs(highnoontargets) do
				if IsValid(v) then
					surface.DrawCircle(v.highnooncirclepos.x, v.highnooncirclepos.y, v:GetNWFloat("HighnoonRadius") + 5, Color(255, 1, 1, 255))

					if v:GetNWBool("IsHighnoonfinished") then
						surface.SetMaterial(Deadeyeicon)
						surface.DrawTexturedRect(v.highnooncirclepos.x - 10, v.highnooncirclepos.y - 10, 20, 20)
					end
				end
			end

			draw.SimpleText(math.Round(LocalPlayer():GetNWInt("HighNoonTimeEnd") - CurTime()), "TargetID", ScrW() / 2, ScrH() / 2 - 50, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	hook.Add("RenderScreenspaceEffects", "BlackandWhite", function()
		if LocalPlayer():GetNWBool("WhiteandBlackHighNoon") and LocalPlayer():Alive() and GetRoundState() == ROUND_ACTIVE and LocalPlayer():IsTerror() then
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
	end)

	hook.Add("HUDPaint", "HighNoonCircles", MakeAHighNoonCircle)

end
