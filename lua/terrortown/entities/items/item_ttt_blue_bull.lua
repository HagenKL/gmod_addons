if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("653258161")
end

ITEM.hud  = Material("vgui/ttt/perks/hud_blue_bull_ttt2.png")
ITEM.EquipMenuData = {
  type = "item_passive",
  name = "Blue Bull",
  desc = "Let you jump more then twice as high. \nAnd this combined with a triple Jump. \nYou also can run faster. \nYou also get less Fall damage.",
}

ITEM.credits = 1
ITEM.material = "vgui/ttt/icon_bluebull"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}
ITEM.corpseDesc = "This Person jumped higher then anybody else.. "

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

hook.Add("SetupMove", "Multi Jump2", function(ply, mv)
	if ply:HasEquipmentItem("item_ttt_blue_bull") then
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

if SERVER then

  hook.Add("TTTPlayerSpeedModifier", "BlueBullSpeed2" , function(ply, _, _, noLag)
  	 if IsValid(ply) and ply:HasEquipmentItem("item_ttt_blue_bull") then
       noLag[1] = noLag[1] * 1.2
     end
  end )

  function ITEM:Bought(ply)
		ply:SetJumpPower(400)-- bit more then twice as much

		ply:SetNWInt("MaxJumpLevel", 2)
		ply:SetNWInt("JumpLevel", 0)
	end

	hook.Add("EntityTakeDamage", "BlueBullFallDamage2", function(ent, dmg)
		if IsValid(ent) and ent:IsPlayer() and ent:HasEquipmentItem("item_ttt_blue_bull") and dmg:IsFallDamage() then
			dmg:ScaleDamage(0.75)  -- reduce the fall damage a bit
		end
	end)

	function ITEM:Reset(ply)
		ply:SetJumpPower(160)
		ply:SetNWInt("JumpLevel", 0)
		ply:SetNWInt("MaxJumpLevel", 1)
	end
end
