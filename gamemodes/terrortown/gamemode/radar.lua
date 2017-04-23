-- Traitor radar functionality


-- should mirror client
local chargetime = 30

local math = math

local function RadarScan(ply, cmd, args)
   if IsValid(ply) and ply:IsTerror() then
      if ply:HasEquipmentItem(EQUIP_RADAR) then

         if ply.radar_charge > CurTime() then
            LANG.Msg(ply, "radar_charging")
            return
         end

         ply.radar_charge =  CurTime() + chargetime
		
         local scan_ents
		 local targets
		 if !ply:IsHunter() then
			 scan_ents = player.GetAll()
			 table.Add(scan_ents, ents.FindByClass("ttt_decoy"))

			 targets = {}
			 for k, p in pairs(scan_ents) do
				if ply == p or (not IsValid(p)) then continue end

				if p:IsPlayer() then
				   if not p:IsTerror() then continue end
				   if p:GetNWBool("disguised", false) and (not ply:IsTraitor() and not ply:IsHunter()) then continue end
				end

				local pos = p:LocalToWorld(p:OBBCenter())

				-- Round off, easier to send and inaccuracy does not matter
				pos.x = math.Round(pos.x)
				pos.y = math.Round(pos.y)
				pos.z = math.Round(pos.z)

				local role = p:IsPlayer() and p:GetRole() or -1

				if not p:IsPlayer() then
				   -- Decoys appear as innocents for non-traitors
				   if not ply:IsTraitor() and not ply:IsHunter() then
					  role = ROLE_INNOCENT
				   end
				elseif role != ROLE_INNOCENT and (role != ply:GetRole() or (ply:IsTraitor() and !p:IsHunter() and !p:IsTraitor())) then
				   -- Detectives/Traitors can see who has their role, but not who
				   -- has the opposite role.
				   role = ROLE_INNOCENT
				end
				
				table.insert(targets, {role=role, pos=pos})
			 end
		 else
			scan_ents = ents.FindByClass("ttt_totem")
			targets = {}
			for k,t in pairs(scan_ents) do
				local pos = t:LocalToWorld(t:OBBCenter())
				
				pos.x = math.Round(pos.x)
				pos.y = math.Round(pos.y)
				pos.z = math.Round(pos.z)

				local owner = t:GetOwner()
				if owner != ply and !owner:IsTraitor() and !owner:IsHunter() then
					table.insert(targets, {role= 4, pos=pos, totem=true})
				end
			end
		 end

         net.Start("TTT_Radar")
            net.WriteUInt(#targets, 8)
            for k, tgt in pairs(targets) do
			   net.WriteUInt(tgt.role, 4)

               net.WriteInt(tgt.pos.x, 32)
               net.WriteInt(tgt.pos.y, 32)
			   if tgt.totem then
				net.WriteInt(tgt.pos.z - 100, 32)
			   else
			    net.WriteInt(tgt.pos.z, 32)
			   end
            end
         net.Send(ply)

      else
         LANG.Msg(ply, "radar_not_owned")
      end
   end
end
concommand.Add("ttt_radar_scan", RadarScan)

