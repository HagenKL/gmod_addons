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
      desc = "The PE will explode every Prop that you want! \nIt looks like an Magnet-O-Stick! \nJust left click a prop and then click rightclick to explode!."
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

if SERVER then
	
	function SWEP:PrimaryAttack()
		if !self.Owner.ExplodeProps or #self.Owner.ExplodeProps == 0 then
			self:SetNextPrimaryFire( CurTime() + 1)
			self:PropExplodeHandler()
		end
	end
	
	function SWEP:SecondaryAttack()
		local ply = self.Owner
		if ply.ExplodeProps and #ply.ExplodeProps > 0 and IsValid(ply) then
			self:PropExploder()
			self:Remove()
		end
	end
	
	function SWEP:SendPEMessage(str)
		net.Start("TTTPEMessage")
		net.WriteString(str)
		net.Send(self.Owner)
	end

	function SWEP:PropExplodeHandler()
		local ply = self.Owner
		local tr = ply:GetEyeTrace()
		local ent = tr.Entity

		if ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" or tr.HitWorld or ent:IsWeapon() then -- A bit of Code from Exho, sorry
			self:SendPEMessage("Fail")
			return
		end
		
		self:SendPEMessage("Succes")
		ply.ExplodeProps = ply.ExplodeProps or {}
		table.insert( ply.ExplodeProps, ent)
	end
	
	function SWEP:PropExploder()
		local ply = self.Owner
		for k,v in pairs(ply.ExplodeProps) do
			if IsValid(v) then
				v:EmitSound("weapons/gamefreak/wtf.mp3" ,400, 200)
				timer.Create("PEPlanting" .. v:EntIndex(), 0.5, 1, function()
					self:ExplodeProp(v)
				end)
			end
		end
		self:SendPEMessage("Exploded")
	end
	
	function SWEP:ExplodeProp(ent)
		if IsValid(v) and IsValid(ply) then
			local expl = ents.Create( "env_explosion" )
			expl:SetPos( v:GetPos() )
			expl:Spawn()
			expl:SetOwner(ply)
			expl:SetKeyValue( "iMagnitude", "0" )
			expl:Fire( "Explode", 0, 0 )
			util.BlastDamage( v, ply, v:GetPos(), 400, 200 )
			expl:EmitSound( "siege/big_explosion.wav", 400, 200 )
			v:Remove()
			table.remove(ply.ExplodeProps,k)
		end
	end
	
	hook.Add("EntityRemoved","EnablePEAgain", function(ent)
		for k,v in pairs(player.GetAll()) do
			if v.ExplodeProps and table.HasValue(v.ExplodeProps, ent) and v:HasWeapon("weapon_ttt_propexploder") then
				table.Empty(v.ExplodeProps)
				v:GetWeapon("weapon_ttt_propexploder"):SendPEMessage("Ready")
			end
		end
	end)
	
elseif CLIENT then

	net.Receive("TTTPEMessage", function()
	local str = net.ReadString()
		if str == "Fail" then
			chat.AddText("Prop Exploder: ", Color(255,255,255), "Are you serious? You can't explode this!")
		elseif str == "Succes" then
			chat.AddText("Prop Exploder: ", Color(255,255,255), "Propexploder planted!")
		elseif str == "Exploded" then
			chat.AddText("Prop Exploder: ", Color(255,255,255), "The selected prop has been exploded!")
		elseif str == "Ready" then
			chat.AddText("Prop Exploder: ", Color(255,255,255), "Your Prop got destroyed, go and search a new prop!")
		end
		chat.PlaySound()
	end)
	
	function SWEP:PrimaryAttack() end
	
end

local function ResettinPropExploder()
	for k,v in pairs(player.GetAll()) do
		timer.Remove("PEPlanting" .. v:EntIndex())
		v.ExplodeProps = {}
	end
end

hook.Add( "TTTPrepareRound", "PEReset", ResettinPropExploder )
