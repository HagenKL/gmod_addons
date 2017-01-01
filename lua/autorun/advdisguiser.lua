if SERVER then
AddCSLuaFile()
end

hook.Add("PostGamemodeLoaded", "TTTInitAdvDisguise", function()
if (GAMEMODE_NAME == "terrortown") then

if CLIENT then
	local function AdvDisguiserInit()

		local GM = gmod.GetGamemode()
		local Player = debug.getregistry().Player

		local oldNick = Player.Nick
		local oldName = Player.Name
		local oldGetName = Player.GetName

		local oldIsDetective = Player.IsDetective
		local oldGetBaseKarma = Player.GetBaseKarma

		local oldTargetID = GM.HUDDrawTargetID
		local oldPlayerID = 13441

		local function tmpNick( ent )
			local client = LocalPlayer()
			if ent:GetNWBool("AdvDisguiseInDisguise") then
				if (client:IsTraitor() and ent:IsTraitor()) or client:IsSpec() then
					return oldNick(ent) .. " (Disguised as " ..  ent:GetNWString("AdvDisguiseName") .. ")"
				else
					return ent:GetNWString("AdvDisguiseName")
				end
			end
			return oldNick( ent )
		end

		local function tmpIsDetective( ent )
			return ent:GetNWBool("AdvDisguiseInDisguise") and ent:GetNWBool("AdvDisguiseIsDetective") or oldIsDetective(ent)
		end

		local function tmpGetBaseKarma( ent )
			return ent:GetNWBool("AdvDisguiseInDisguise") and ent:GetNWInt("AdvDisguiseKarma") or oldGetBaseKarma(ent)
		end

		GM.HUDDrawTargetID = function()
		    local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)
            local ent = trace.Entity
			Player.Nick = tmpNick
			Player.Name = tmpNick
			Player.GetName = tmpNick
			Player.IsDetective = tmpIsDetective
			Player.GetBaseKarma = tmpGetBaseKarma

			for _, ply in pairs ( player.GetAll() ) do
				if ply:GetNWBool("AdvDisguiseInDisguise") and IsValid(ply:GetNWEntity("AdvDisguiseEnt",nil)) then
					ply.old_sb_tag = ply.sb_tag
					ply.sb_tag = ply:GetNWEntity("AdvDisguiseEnt",nil).sb_tag
				end
			end

			oldTargetID()

			local client = LocalPlayer()
			if IsValid(client.last_id) and client.last_id:IsPlayer() and client.last_id:GetNWBool("AdvDisguiseInDisguise") then
				client.last_id = client.last_id:GetNWEntity("AdvDisguiseEnt",nil)
			end

			for _, ply in pairs ( player.GetAll() ) do
				if ply.old_sb_tag then
					ply.sb_tag = ply.old_sb_tag
					ply.old_sb_tag = nil
				end
			end

			Player.Nick = oldNick
			Player.Name = oldName
			Player.GetName = oldGetName
			Player.IsDetective = oldIsDetective
			Player.GetBaseKarma = oldGetBaseKarma
		end

		local function AdvDisguiseDraw()
			local client = LocalPlayer()
			if not IsValid(client) then return end
			if not client:GetNWBool("AdvDisguiseInDisguise") then return end

			surface.SetFont("TabLarge")
			surface.SetTextColor(255, 0, 0, 230)

			local text = "You are disguised as " .. client:GetNWString("AdvDisguiseName")
			local w, h = surface.GetTextSize(text)

			surface.SetTextPos(36, ScrH() - 150 - h)
			surface.DrawText(text)
		end
		hook.Add("HUDPaint","AdvDisguiseDraw", AdvDisguiseDraw)

		function RADIO:GetTargetType()
			if not IsValid(LocalPlayer()) then return end
			local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)

			if not trace or (not trace.Hit) or (not IsValid(trace.Entity)) then return end

			local ent = trace.Entity

			if ent:IsPlayer() then
				if ent:GetNWBool("disguised", false) then
					return "quick_disg", true
				elseif ent:GetNWBool("AdvDisguiseInDisguise", false) then
					if IsValid(ent:GetNWEntity("AdvDisguiseEnt",nil)) then
						return ent:GetNWEntity("AdvDisguiseEnt",nil), false
					else
						return nil, false
					end

				else
					return ent, false
				end
			elseif ent:GetClass() == "prop_ragdoll" and CORPSE.GetPlayerNick(ent, "") != "" then
				if DetectiveMode() and not CORPSE.GetFound(ent, false) then
					return "quick_corpse", true
				else
					return ent, false
				end
			end
		end
	end
	hook.Add( 'PostGamemodeLoaded', 'AdvDisguiserInit', function() timer.Simple( 0.5, AdvDisguiserInit ) end )

elseif SERVER then

	resource.AddFile("materials/VGUI/ttt/icon_adv_disguiser.vmt")
	local function AdvDisguiseReset()
		for _,ply in pairs (player.GetAll()) do
			ply:SetNWString( "AdvDisguiseName", "" )
			ply:SetNWBool( "AdvDisguiseIsDetective", false )
			ply:SetNWInt( "AdvDisguiseKarma", 0 )
			ply:SetNWEntity( "AdvDisguiseEnt", nil )
			ply:SetNWBool( "AdvDisguiseInDisguise", false )
		end
	end
	hook.Add("TTTPrepareRound","AdvDisguiseReset ", AdvDisguiseReset )

end

end end)
