-- Snacktopia client: builds the HUD and keeps it in step with the server.
-- All game numbers live on the server as player attributes; this script only
-- reads them and draws them, so the client can never lie about the score.

local Players = game:GetService("Players")

local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hud = Hud.Build(playerGui)

local toastUntil = 0

local function refreshMoney()
	local money = player:GetAttribute("Money") or 0
	local income = player:GetAttribute("Income") or 0
	hud.moneyLabel.Text = "$" .. tostring(money)
	hud.incomeLabel.Text = "+$" .. tostring(income) .. " / second"
end

local function refreshGoal()
	local goal = player:GetAttribute("Goal") or "Fuse all 3 hybrids: 0/3"
	local carrying = player:GetAttribute("Carrying") or ""
	local carriedCount = player:GetAttribute("CarriedCount") or 0
	local placedCount = player:GetAttribute("PlacedCount") or 0
	hud.goalLabel.Text = goal .. "   |   Base: " .. tostring(placedCount) .. "/6"
	if carrying == "" then
		hud.carryingLabel.Text = "Carrying: nothing yet"
	else
		hud.carryingLabel.Text = "Carrying (" .. tostring(carriedCount) .. "/2): " .. carrying
	end
end

local function refreshWave()
	local state = player:GetAttribute("WaveState") or "calm"
	local timer = player:GetAttribute("WaveTimer") or 0
	if state == "warning" then
		hud.waveLabel.Text = "GOBLIN WAVE IN " .. tostring(timer) .. "s - RUN HOME!"
		hud.waveLabel.TextColor3 = Color3.fromRGB(255, 120, 60)
		hud.wavePanel.BackgroundColor3 = Color3.fromRGB(90, 40, 10)
	elseif state == "wave" then
		hud.waveLabel.Text = "GOBLIN WAVE! Defend your base!"
		hud.waveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		hud.wavePanel.BackgroundColor3 = Color3.fromRGB(90, 10, 10)
	else
		hud.waveLabel.Text = "Next Goblin Wave: " .. tostring(timer) .. "s"
		hud.waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		hud.wavePanel.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
	end
end

local function showToast()
	local message = player:GetAttribute("Toast") or ""
	if message == "" then
		return
	end
	hud.toastLabel.Text = message
	hud.toastLabel.Visible = true
	toastUntil = tick() + 4
	task.delay(4, function()
		if tick() >= toastUntil then
			hud.toastLabel.Visible = false
		end
	end)
end

local function refreshBase()
	local color = player:GetAttribute("BaseColor") or "?"
	hud.baseLabel.Text = "Your base: " .. color
end

local function refreshAll()
	refreshMoney()
	refreshGoal()
	refreshWave()
	refreshBase()
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

refreshAll()
