local files, _ = file.Find("vote/roles/*.lua", "LUA")

for _, fil in pairs(files) do
	if SERVER then AddCSLuaFile("vote/roles/" .. fil) end
	include("vote/roles/" .. fil)
end
