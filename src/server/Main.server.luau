-- Server bootstrap: bases, placing brainrots, player join and leave, the
-- income tick, and starting the spawner, the Fusion Kitchen, and the waves.

local Players = game:GetService("Players")

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)
local Spawner = require(script.Parent.Spawner)
local Fusion = require(script.Parent.Fusion)
local Waves = require(script.Parent.Waves)

local BASE_COLORS = { "Red", "Blue", "Yellow", "Green" }

local pads = {}
local spawns = {}
for i = 1, 4 do
	pads[i] = workspace:WaitForChild("Base" .. i)
	spawns[i] = workspace:WaitForChild("Spawn" .. i)
end

local owners = {}

local function slotOffset(slot)
	local column = (slot - 1) % 3
	local row = math.floor((slot - 1) / 3)
	return Vector3.new((column - 1) * 6, 0, (row - 0.5) * 6)
end

local function buildPlacedPart(state, entry)
	local def = Catalog.GetById(entry.Id)
	if not def then
		return
	end
	local pad = state.BasePart
	local offset = slotOffset(entry.Slot)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(3.5, 3.5, 3.5)
	ball.Color = def.Color
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = false
	ball.Position = pad.Position + Vector3.new(offset.X, 2.5, offset.Z)
	ball.Name = def.Name
	ball.Parent = workspace
	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(140, 40)
	label.StudsOffset = Vector3.new(0, 3, 0)
	label.AlwaysOnTop = true
	label.Parent = ball
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = string.format("%s  $%d/s", def.Name, def.Rate)
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextStrokeTransparency = 0
	text.Parent = label
	entry.Part = ball
end

local function makePlacePrompt(pad, index)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Place brainrot on your base"
	prompt.ObjectText = "Your base"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		local state = PlayerData.Get(player)
		if not state then
			return
		end
		if state.BasePart ~= pad then
			PlayerData.Toast(state, string.format("That is not your base! Yours is the %s one.", BASE_COLORS[state.BaseIndex]))
			return
		end
		if #state.Carried == 0 then
			PlayerData.Toast(state, "You carry no brainrot! Catch one in the Wild Meadow first.")
			return
		end
		local firstId = state.Carried[1]
		local slot = PlayerData.TryPlace(state, firstId)
		if not slot then
			PlayerData.Toast(state, "Your base is full! Fuse brainrots in the Fusion Kitchen to make room.")
			return
		end
		local entry = nil
		for _, placed in ipairs(state.Placed) do
			if placed.Slot == slot then
				entry = placed
				break
			end
		end
		if entry then
			buildPlacedPart(state, entry)
		end
		PlayerData.Sync(state)
		local def = Catalog.GetById(firstId)
		if def then
			PlayerData.Toast(state, string.format("%s is on your base, earning $%d every second!", def.Name, def.Rate))
		end
	end)
end

for i, pad in ipairs(pads) do
	makePlacePrompt(pad, i)
end

local function onPlayerAdded(player)
	local baseIndex = 1
	for i = 1, 4 do
		if not owners[i] then
			baseIndex = i
			break
		end
	end
	owners[baseIndex] = player
	local state = PlayerData.Create(player, baseIndex, pads[baseIndex])
	player:SetAttribute("BaseColor", BASE_COLORS[baseIndex])
	player.RespawnLocation = spawns[baseIndex]
	PlayerData.Toast(state, string.format(
		"Welcome to Snacktopia! Your base is %s. Catch brainrots in the meadow, carry them home, and place them on your base.",
		BASE_COLORS[baseIndex]
	))
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		root.CFrame = spawns[baseIndex].CFrame + Vector3.new(0, 3, 0)
	end)
end

local function onPlayerRemoving(player)
	local state = PlayerData.Get(player)
	if state then
		for _, placed in ipairs(state.Placed) do
			if placed.Part then
				placed.Part:Destroy()
			end
		end
		owners[state.BaseIndex] = nil
	end
	PlayerData.Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = PlayerData.Get(player)
			if state then
				local income = PlayerData.Income(state)
				if income > 0 then
					PlayerData.AddMoney(state, income)
					PlayerData.Sync(state)
				end
			end
		end
	end
end)

Spawner.Start()
Fusion.Start()
Waves.Start(pads)

print("Snacktopia server running: catch, carry, place, fuse, and run home before the goblins come!")
