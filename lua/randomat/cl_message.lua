surface.CreateFont("RandomatHeader", {
	font = "Roboto",
	size = 48
})

surface.CreateFont("RandomatSmallMsg", {
	font = "Roboto",
	size = 32
})

local MainData
local SubData = nil

net.Receive("randomat_message", function()
	local t = net.ReadUInt(8)
	local msg = net.ReadString()
	local length = net.ReadUInt(8)
	if length == 0 then length = 5 end

	local data = {
		Message = msg,
		Length = length
	}

	if t == 1 then
		MainData = data
	elseif t == 2 then
		SubData = data
	end

	-- Paint Message
	local width = ScrW() / 3

	NotifyPanel = vgui.Create("DNotify")
	NotifyPanel:SetPos(ScrW() / 2 - width / 2, ScrH() / 2 - 50)
	NotifyPanel:SetSize(width, 100)

	local bg = vgui.Create("DPanel", NotifyPanel)
	bg:SetBackgroundColor(Color(0, 0, 0, 200))
	bg:Dock(FILL)

	if MainData then
		local lbl = vgui.Create("DLabel", bg)
		lbl:SetText(MainData.Message)
		lbl:SetFont("RandomatHeader")
		lbl:SetTextColor(Color(255, 200, 0))
		lbl:SetWrap(true)
		lbl:Dock(FILL)

		local w, h = lbl:GetSize()
		local tw, th = lbl:GetTextSize()

		lbl:SetPos(w / 2 - tw / 2, 10)
	end

	if SubData then
		local lbl = vgui.Create("DLabel", bg)
		lbl:SetPos(10, 10)
		lbl:SetText(SubData.Message)
		lbl:SetFont("RandomatSmallMsg")
		lbl:SetTextColor(Color(255, 200, 0))
		lbl:SizeToContents()
	end

	NotifyPanel:AddItem(bg)
	surface.PlaySound("weapons/c4_initiate.wav")
end)
