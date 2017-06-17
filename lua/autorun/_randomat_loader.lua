Randomat = Randomat or {}

local function AddServer(fil)
	if SERVER then include(fil) end
end

local function AddClient(fil)
	if SERVER then AddCSLuaFile(fil) end
	if CLIENT then include(fil) end
end

AddServer("randomat/randomat_base.lua")
AddClient("randomat/cl_message.lua")
AddClient("randomat/cl_networkstrings.lua")

local files, _ = file.Find("randomat/events/*.lua", "LUA")

for _, fil in pairs(files) do
	AddServer("randomat/events/" .. fil)
end
