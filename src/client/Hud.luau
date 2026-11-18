-- Builds the whole Snacktopia HUD inside a player's PlayerGui and hands back
-- every label the client keeps in step with the server's attributes.

local Hud = {}

local function makePanel(parent, name, anchor, position, size, color)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = anchor
	panel.Position = position
	panel.Size = size
	panel.BackgroundColor3 = color
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	return panel
end

local function makeLabel(parent, name, position, size, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

function Hud.Build(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SnacktopiaHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local moneyPanel = makePanel(gui, "MoneyPanel", Vector2.new(0, 0),
		UDim2.fromOffset(16, 16), UDim2.fromOffset(280, 92), Color3.fromRGB(30, 40, 70))
	local moneyLabel = makeLabel(moneyPanel, "MoneyLabel",
		UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 48), "$100", 40, Color3.fromRGB(255, 220, 60))
	local incomeLabel = makeLabel(moneyPanel, "IncomeLabel",
		UDim2.fromOffset(12, 56), UDim2.new(1, -24, 0, 28), "+$0 / second", 22, Color3.fromRGB(90, 220, 120))

	local wavePanel = makePanel(gui, "WavePanel", Vector2.new(0.5, 0),
		UDim2.new(0.5, -180, 0, 16), UDim2.fromOffset(360, 56), Color3.fromRGB(25, 70, 40))
	local waveLabel = makeLabel(wavePanel, "WaveLabel",
		UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), "Next Goblin Wave: 100s", 26, Color3.fromRGB(255, 255, 255))
	waveLabel.TextXAlignment = Enum.TextXAlignment.Center

	local goalPanel = makePanel(gui, "GoalPanel", Vector2.new(1, 0),
		UDim2.new(1, -16, 0, 16), UDim2.fromOffset(280, 120), Color3.fromRGB(60, 25, 80))
	local goalLabel = makeLabel(goalPanel, "GoalLabel",
		UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 30), "Fuse all 3 hybrids: 0/3", 22, Color3.fromRGB(255, 150, 220))
	local carryingLabel = makeLabel(goalPanel, "CarryingLabel",
		UDim2.fromOffset(12, 42), UDim2.new(1, -24, 0, 44), "Carrying: nothing yet", 20, Color3.fromRGB(255, 255, 255))
	carryingLabel.TextWrapped = true
	local baseLabel = makeLabel(goalPanel, "BaseLabel",
		UDim2.fromOffset(12, 88), UDim2.new(1, -24, 0, 26), "Your base: ?", 20, Color3.fromRGB(150, 200, 255))

	local toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "ToastLabel"
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -80)
	toastLabel.Size = UDim2.fromOffset(640, 44)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Text = ""
	toastLabel.TextSize = 24
	toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	toastLabel.Font = Enum.Font.GothamBold
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	toastLabel.TextStrokeTransparency = 0
	toastLabel.Visible = false
	toastLabel.Parent = gui

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "HintLabel"
	hintLabel.AnchorPoint = Vector2.new(0, 1)
	hintLabel.Position = UDim2.new(0, 16, 1, -16)
	hintLabel.Size = UDim2.fromOffset(900, 24)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "WASD to move  |  Hold E on a brainrot to buy  |  Carry max 2  |  Fuse 2 at the Fusion Kitchen"
	hintLabel.TextSize = 18
	hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.TextXAlignment = Enum.TextXAlignment.Left
	hintLabel.TextStrokeTransparency = 0
	hintLabel.Parent = gui

	return {
		Gui = gui,
		MoneyLabel = moneyLabel,
		IncomeLabel = incomeLabel,
		WavePanel = wavePanel,
		WaveLabel = waveLabel,
		GoalLabel = goalLabel,
		CarryingLabel = carryingLabel,
		BaseLabel = baseLabel,
		ToastLabel = toastLabel,
		HintLabel = hintLabel,
	}
end

return Hud
