if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("653258161")
end

EQUIP_BLUE_BULL = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 16

local bluebull = {
	id = EQUIP_BLUE_BULL,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_bluebull",
	name = "Blue Bull",
	desc = "Let you jump more then twice as high. \nAnd this combined with a triple Jump. \nYou also can run faster. \nYou also get less Fall damage.",
	hud = true
}

local detectiveCanUse = CreateConVar("ttt_bluebull_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the Blue Bull.")
local traitorCanUse = CreateConVar("ttt_bluebull_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the Blue Bull.")

if (detectiveCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], bluebull)
end
if (traitorCanUse:GetBool()) then
	table.insert(EquipmentItems[ROLE_TRAITOR], bluebull)
end

local function GetMoveVector(mv)
	local ang = mv:GetAngles()

	local max_speed = mv:GetMaxSpeed()

	local forward = math.Clamp(mv:GetForwardSpeed(), -max_speed, max_speed)
	local side = math.Clamp(mv:GetSideSpeed(), -max_speed, max_speed)

	local abs_xy_move = math.abs(forward) + math.abs(side)

	if abs_xy_move == 0 then
		return Vector(0, 0, 0)
	end

	local mul = max_speed / abs_xy_move

	local vec = Vector()

	vec:Add(ang:Forward() * forward)
	vec:Add(ang:Right() * side)

	vec:Mul(mul)

	return vec
end

hook.Add("SetupMove", "Multi Jump", function(ply, mv)
	if ply:HasEquipmentItem(EQUIP_BLUE_BULL) then
		-- Let the engine handle movement from the ground
		if ply:OnGround() then
			ply:SetNWInt("JumpLevel", 0)

			return
		end

		-- Don't do anything if not jumping
		if not mv:KeyPressed(IN_JUMP) then
			return
		end

		ply:SetNWInt("JumpLevel", ply:GetNWInt("JumpLevel") + 1)

		if ply:GetNWInt("JumpLevel") > ply:GetNWInt("MaxJumpLevel") then
			return
		end

		local vel = GetMoveVector(mv)

		vel.z = ply:GetJumpPower()

		mv:SetVelocity(vel)

		ply:DoCustomAnimEvent(PLAYERANIMEVENT_JUMP , -1)
	end
end )

hook.Add("TTTPlayerSpeedModifier", "BlueBullSpeed" , function(ply)
	if ply:HasEquipmentItem(EQUIP_BLUE_BULL) and !ply:GetNWBool("DRDead") and !ply:GetActiveWeapon() == "weapon_ttt_homebat" and !ply:GetNWBool("ItsHighNoon") and !ply:GetNWBool("ItsHighNoonshooting") and !ply.RandomatSuperSpeed and !ply.RandomatSpeed then
		 return 1.2 -- a little speed buff
	end
end )

if SERVER then

	hook.Add("TTTOrderedEquipment", "TTTBlueBull3", function(ply, equipment, is_item)
		 if is_item == EQUIP_BLUE_BULL then
			ply:SetJumpPower(400)-- bit more then twice as much
			ply:SetNWInt("MaxJumpLevel", 2)
			ply:SetNWInt("JumpLevel", 0)
			ply.BoughtBlueBull = true
		end
	end )
	
	hook.Add("EntityTakeDamage", "BlueBullFallDamage", function(ent, dmg)
		if IsValid(ent) and ent:IsPlayer() and ent:HasEquipmentItem(EQUIP_BLUE_BULL) and dmg:IsFallDamage() then
			dmg:ScaleDamage(0.75)  -- reduce the fall damage a bit
		end
	end)
	hook.Add( "TTTPrepareRound", "TTTBlueBull", function()
		for k, v in pairs(player.GetAll()) do
			v:SetJumpPower(160)
			v:SetNWInt("JumpLevel", 0)
			v:SetNWInt("MaxJumpLevel", 1)
			v.BoughtBlueBull = false
		end
	end)
	hook.Add("PlayerDeath", "TTTBlueBull2", function(ply)
		if ply.BoughtBlueBull then
			ply.BoughtBlueBull = false
			ply:SetJumpPower(160)
		end
	end)
	hook.Add("PlayerSpawn", "TTTBlueBull2", function(ply)
		if ply.BoughtBlueBull then
			ply.BoughtBlueBull = false
			ply:SetJumpPower(160)
		end
	end)

	else
		-- feel for to use this function for your own perk, but please credit Zaratusa
		-- your perk needs a "hud = true" in the table, to work properly
		  local defaultY = ScrH() / 2 + 20
		  local function getYCoordinate(currentPerkID)
		    local amount, i, perk = 0, 1
		    while (i < currentPerkID) do

		      local role = LocalPlayer():GetRole()

		      if role == ROLE_INNOCENT then --he gets it in a special way
		        if GetEquipmentItem(ROLE_TRAITOR, i).id then
		          role = ROLE_TRAITOR -- Temp fix what if a perk is just for Detective
		        elseif GetEquipmentItem(ROLE_DETECTIVE, i).id then
		          role = ROLE_DETECTIVE
		        end
		      end

		      perk = GetEquipmentItem(role, i)

		      if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
		        amount = amount + 1
		      end
		      i = i * 2
		    end

		    return defaultY - 80 * amount
		  end

		local yCoordinate = defaultY
		-- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
		hook.Add("TTTBoughtItem", "TTTBlueBull2", function()
			if (LocalPlayer():HasEquipmentItem(EQUIP_BLUE_BULL)) then
				yCoordinate = getYCoordinate(EQUIP_BLUE_BULL)
			end
		end)
		local material = Material("vgui/ttt/perks/hud_blue_bull.png")
		hook.Add("HUDPaint", "TTTBlueBull", function()
			if (LocalPlayer():HasEquipmentItem(EQUIP_BLUE_BULL)) then
				surface.SetMaterial(material)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(20, yCoordinate, 64, 64)
			end
		end)

		hook.Add("TTTBodySearchEquipment", "BlueBullCorpseIcon", function(search, eq)
				search.eq_bluebull = util.BitSet(eq, EQUIP_BLUE_BULL)
			end )

		hook.Add("TTTBodySearchPopulate", "BlueBullCorpseIcon", function(search, raw)
				if (!raw.eq_bluebull) then
					return end

					local highest = 0
					for _, v in pairs(search) do
						highest = math.max(highest, v.p)
					end

					search.eq_bluebull = {img = "vgui/ttt/icon_bluebull", text = "They drunk a Blue Bull.", p = highest + 1}
			end )
end
