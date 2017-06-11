util.AddNetworkString("randomat_message")

Randomat.Events = Randomat.Events or {}
Randomat.ActiveEvent = nil

local function shuffleTable(t)
	math.randomseed(os.time())
	local rand = math.random

	local interactions = #t
	local j

	for i = interactions, 2, -1 do
		j = rand(i)
		t[i], t[j] = t[j], t[i]
	end
end

local randomat_meta =  {}
randomat_meta.__index = randomat_meta

function Randomat:register(id, tbl)
	tbl.Id = id
	tbl.__index = tbl
	setmetatable(tbl, randomat_meta)

	Randomat.Events[id] = tbl
end

function Randomat:TriggerRandomEvent()
	local events = Randomat.Events

	shuffleTable(events)

	Randomat.ActiveEvent = table.Random(events)

	Randomat:EventNotify(Randomat.ActiveEvent.Title)
	Randomat.ActiveEvent:Begin()

	if Randomat.ActiveEvent.Time != nil then
		timer.Simple(Randomat.ActiveEvent.Time or 60, function()
			Randomat.ActiveEvent:End()
			Randomat.ActiveEvent = nil
		end)
	end
end

function Randomat:EventNotify(title)
	net.Start("randomat_message")
	net.WriteUInt(1, 8)
	net.WriteString(title)
	net.WriteUInt(0, 8)
	net.Broadcast()
end

/**
 * Randomat Meta
 */

-- Valid players not spec
function randomat_meta:GetPlayers(shuffle)
	local plys = {}

	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and (not ply:IsSpec()) then
			table.insert(plys, ply)
		end
	end

	if shuffle then
		shuffleTable(plys)
	end

	return plys
end

if SERVER then
	function randomat_meta:SmallNotify(msg, length, targ)
		net.Start("randomat_message")
		net.WriteUInt(2, 8)
		net.WriteString(msg)
		net.WriteUInt(length, 0, 8)
		if not targ then net.Broadcast() else net.Send(targ) end
	end
end

function randomat_meta:AddHook(hooktype, callbackfunc)
	callbackfunc = callbackfunc or self[hooktype]

	hook.Add(hooktype, "RandomatEvent" .. self.Id .. ":" .. hooktype, function(...)
		return callbackfunc(self, ...)
	end)

	self.Hooks = self.Hooks or {}
	table.insert(self.Hooks, {hooktype, "RandomatEvent" .. self.Id .. ":" .. hooktype})
end

function randomat_meta:CleanUpHooks()
	if not self.Hooks then return end

	for _, ahook in pairs(self.Hooks) do
		hook.Remove(ahook[1], ahook[2])
	end

	table.Empty(self.Hooks)
end

function randomat_meta:Begin() end

function randomat_meta:End()
	self:CleanUpHooks()
end


/*
 * Override TTT Stuff
 */
hook.Add("TTTEndRound", "RandomatEndRound", function()
	if Randomat.ActiveEvent != nil then
		Randomat.ActiveEvent:End()
		Randomat.ActiveEvent = nil
	end
end)
