util.AddNetworkString("randomat_message")

Randomat.Events = Randomat.Events or {}
Randomat.ActiveEvents = {}

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

local function eventIndex()
	math.randomseed(os.time())
	local length = math.random(1, 10)

	if length < 1 then return end

	for i = 1, length do
		result = result .. string.char(math.random(32, 126))
	end

	return result
end

function Randomat:register(id, tbl)
	tbl.Id = id
	tbl.__index = tbl
	setmetatable(tbl, randomat_meta)

	Randomat.Events[id] = tbl
end

function Randomat:TriggerRandomEvent(ply)
	local events = Randomat.Events
	local __index = eventIndex()

	shuffleTable(events)

	Randomat.ActiveEvents[__index] = table.Random(events)
	Randomat.ActiveEvents[__index].Owner = ply

	Randomat:EventNotify(Randomat.ActiveEvents[__index].Title)
	Randomat.ActiveEvents[__index]:Begin()

	if Randomat.ActiveEvents[__index].Time != nil then
		timer.Simple(Randomat.ActiveEvents[__index].Time or 60, function()
			Randomat.ActiveEvents[__index]:End()
			table.remove(Randomat.ActiveEvents, __index)
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
local randomat_meta =  {}
randomat_meta.__index = randomat_meta

-- Valid players not spec
function randomat_meta:GetPlayers(shuffle)
	return self:GetAlivePlayers(shuffle)
end

function randomat_meta:GetAlivePlayers(shuffle)
	local plys = {}

	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and (not ply:IsSpec()) and ply:Alive() then
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

	hook.Add(hooktype, "RandomatEvent." .. self.Owner:UniqueID() .. "." .. self.Id .. ":" .. hooktype, function(...)
		return callbackfunc(self, ...)
	end)

	self.Hooks = self.Hooks or {}
	table.insert(self.Hooks, {hooktype, "RandomatEvent." .. self.Owner:UniqueID() .. "." .. self.Id .. ":" .. hooktype})
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
	if Randomat.ActiveEvents != {} then
		for _, evt in pairs(Randomat.ActiveEvents) do
			evt:End()
		end

		Randomat.ActiveEvents = {}
	end
end)
