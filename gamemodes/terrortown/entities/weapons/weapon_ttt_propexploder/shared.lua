//GeneralSettings\\
SWEP.Base				= "weapon_tttbase"
SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.HoldType = "pistol"
SWEP.AdminSpawnable = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Kind = WEAPON_EQUIP2


//Serverside\\
if SERVER then
   AddCSLuaFile( "shared.lua" )
   resource.AddFile("materials/VGUI/ttt/icon_propexploder.vmt")
   resource.AddWorkshop("680737032")
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

//Clientside\\
if CLIENT then

   SWEP.PrintName    = "Prop Exploder"
   SWEP.Slot         = 7

   SWEP.ViewModelFOV  = 70
   SWEP.ViewModelFlip = false

      SWEP.Icon = "VGUI/ttt/icon_propexploder"
      SWEP.EquipMenuData = {
      type = "weapon",
      desc = "The PE will explode every Prop that you want! \nIt looks like an Magnet-O-Stick! \nJust left click a prop and then click rightclick."
   };
   	net.Receive("ColoredMessage",function(len)
		local msg = net.ReadTable()
		chat.AddText(unpack(msg))
		chat.PlaySound()
		end)
end

//Damage\\
SWEP.Primary.Delay       = 2
SWEP.Primary.Recoil      = 0
SWEP.Primary.Automatic   = false
SWEP.Primary.NumShots 	 = 0
SWEP.Primary.Damage      = 0
SWEP.Primary.Cone        = 0.0001
SWEP.Primary.Ammo        = -1
SWEP.Primary.ClipSize    = -1
SWEP.Primary.ClipMax     = -1
SWEP.Primary.DefaultClip = -1
SWEP.AmmoEnt = ""


//Verschiedenes\\
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.UseHands = true
SWEP.HeadshotMultiplier = 0
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.LimitedStock = false

//Sounds/Models\\
SWEP.ViewModel          = Model("models/weapons/v_stunbaton.mdl")
SWEP.WorldModel         = Model("models/weapons/w_stunbaton.mdl")
SWEP.Weight = 5

function SWEP:OnRemove()
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
		RunConsoleCommand("lastinv")
	end
end
if CLIENT then
function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end
end
if SERVER then
local PropExploderUsed = false
local ExplodeProps = {}
function SWEP:PrimaryAttack()
	if not PropExploderUsed then
	self:SetNextPrimaryFire( CurTime() + 1)
	self:PropExplodeHandler()
	end
end
function SWEP:SecondaryAttack()
	local ply = self.Owner
	if ply.ExplodeProp and IsValid(ply) then
		PropExploder(ply)
		PropExploderUsed = false
		self:Remove()
	end
end
local seen
function SWEP:PropExplodeHandler()
	local ply = self.Owner
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity

		if ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" or tr.HitWorld or ent:IsWeapon() then -- A bit of Code from Exho
			ply:PlayerMsg("Prop Exploder: ", Color(255,255,255), "This is not a valid Prop!")
			return
		elseif IsValid(ent) then
			if string.sub( ent:GetClass(), 1, 5 ) ~= "prop_" then -- The last check
				ply:PlayerMsg( "Prop Exploder: ", Color(255,255,255), "This is not a valid Prop!")
				return
			end
		end
			ply:PlayerMsg("Prop Exploder: ", Color(255,255,255), "PropExploder activated")
			PropExploderUsed = true
			timer.Create("ExplodePropReady" .. ply:EntIndex(),0.51, 1, function()
				ply.ExplodeProp = true
				table.insert( ExplodeProps, ent)
				SendWarnPE(true, ent, ply)
			end )
	timer.Create("PropExplodeFixError" .. ply:EntIndex(), 0.1, 0, function()
		for k,ent in pairs(ExplodeProps) do
			if not IsValid(ent) then
				SendWarnPE(false, ent, v)
			end
		end
	end)
	function SendWarnPE(armed ,ent, owner)
		if (IsValid(owner) and owner:IsRole(ROLE_TRAITOR)) and IsValid(ent) then
			net.Start("TTT_PEWarning")
			net.WriteUInt(ent:EntIndex(), 16)
			net.WriteBool(armed)
			net.WriteVector(ent:GetPos())
			net.Send(GetTraitorFilter(true))
		end
	end
	end
function PropExploder(ply)
			ply.ExplodeProp = false
			ply:PlayerMsg("Prop Exploder: ", Color(255,255,255), "Prop has been exploded!")
			for k,v in pairs(ExplodeProps) do
				if IsValid(v) then
					v:EmitSound("weapons/gamefreak/wtf.mp3" ,400, 200)
					SendWarnPE(false, v, ply)
					timer.Create("Explodewaiting" .. v:EntIndex(), 0.5, 1, function()
						if IsValid(v) and IsValid(ply) then
							local expl = ents.Create( "env_explosion" )
							expl:SetPos( v:GetPos() )
							expl:Spawn()
							expl:SetOwner(ply)
							expl:SetKeyValue( "iMagnitude", "0" )
							expl:Fire( "Explode", 0, 0 )
							util.BlastDamage( v, ply, v:GetPos(), 400, 200 )
							expl:EmitSound( "siege/big_explosion.wav", 400, 200 )
						end
						timer.Create("PropRemove" .. v:EntIndex() , 0, 1, function()
							if IsValid(v) then
								v:Remove()
							end
					end)
				end )
			end
		end
		ExplodeProps = {}
	end
end

local function ResettinPropExploder()
	for k,v in pairs(player.GetAll()) do
		v.ExplodeProp = false
		timer.Remove("ExplodePropReady" .. v:EntIndex())
		timer.Remove("PropExplodeFixError" .. v:EntIndex())
		timer.Remove("Explodewaiting" .. v:EntIndex())
		timer.Remove("PropRemove" .. v:EntIndex())
	end
	ExplodeProps = {}
end

hook.Add( "TTTPrepareRound", "ASCRESET", ResettinPropExploder )
