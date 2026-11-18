-- Client entry: builds the HUD and keeps it in step with the server by reading
-- the local player's attributes. It never trusts its own copy of the numbers.

local Players = game:GetService("Players")

local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local hud = Hud.Build(player:WaitForChild("PlayerGui"))

local function refreshMoney()
	local money = player:GetAttribute("Money") or 0
	local income = player:GetAttribute("Income") or 0
	hud.MoneyLabel.Text = "$" .. tostring(money)
	hud.IncomeLabel.Text = "+$" .. tostring(income) .. " / second"
end

local function refreshGoal()
	local goal = player:GetAttribute("Goal") or "Fuse all 3 hybrids: 0/3"
	local placed = player:GetAttribute("PlacedCount") or 0
	hud.GoalLabel.Text = goal .. "   |   Base: " .. tostring(placed) .. "/6"
	local carrying = player:GetAttribute("Carrying") or ""
	local carried = player:GetAttribute("CarriedCount") or 0
	if carrying == "" then
		hud.CarryingLabel.Text = "Carrying: nothing yet"
	else
		hud.CarryingLabel.Text = string.format("Carrying (%d/2): %s", carried, carrying)
	end
end

local function refreshWave()
	local state = player:GetAttribute("WaveState") or "calm"
	local timer = player:GetAttribute("WaveTimer") or 100
	if state == "warning" then
		hud.WaveLabel.Text = string.format("GOBLIN WAVE IN %ds - RUN HOME!", timer)
		hud.WaveLabel.TextColor3 = Color3.fromRGB(255, 170, 40)
		hud.WavePanel.BackgroundColor3 = Color3.fromRGB(90, 60, 20)
	elseif state == "wave" then
		hud.WaveLabel.Text = "GOBLIN WAVE! Defend your base!"
		hud.WaveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		hud.WavePanel.BackgroundColor3 = Color3.fromRGB(90, 20, 20)
	else
		hud.WaveLabel.Text = string.format("Next Goblin Wave: %ds", timer)
		hud.WaveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		hud.WavePanel.BackgroundColor3 = Color3.fromRGB(25, 70, 40)
	end
end

local function refreshBase()
	local color = player:GetAttribute("BaseColor") or "?"
	hud.BaseLabel.Text = "Your base: " .. color
end

local lastToastId = 0
local function showToast()
	local toastId = player:GetAttribute("ToastId") or 0
	if toastId == lastToastId then
		return
	end
	lastToastId = toastId
	local message = player:GetAttribute("Toast") or ""
	hud.ToastLabel.Text = message
	hud.ToastLabel.Visible = true
	local shownId = toastId
	task.delay(4, function()
		if lastToastId == shownId then
			hud.ToastLabel.Visible = false
		end
	end)
end

player:GetAttributeChangedSignal("Money"):Connect(refreshMoney)
player:GetAttributeChangedSignal("Income"):Connect(refreshMoney)
player:GetAttributeChangedSignal("Goal"):Connect(refreshGoal)
player:GetAttributeChangedSignal("Carrying"):Connect(refreshGoal)
player:GetAttributeChangedSignal("CarriedCount"):Connect(refreshGoal)
player:GetAttributeChangedSignal("PlacedCount"):Connect(refreshGoal)
player:GetAttributeChangedSignal("WaveState"):Connect(refreshWave)
player:GetAttributeChangedSignal("WaveTimer"):Connect(refreshWave)
player:GetAttributeChangedSignal("BaseColor"):Connect(refreshBase)
player:GetAttributeChangedSignal("ToastId"):Connect(showToast)

refreshMoney()
refreshGoal()
refreshWave()
refreshBase()
