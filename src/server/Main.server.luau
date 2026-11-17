-- Snacktopia server bootstrap: hands every player a base, starts the spawner,
-- the Fusion Kitchen and the goblin waves, ticks income once a second, and
-- places carried brainrots on their owner's base when the base prompt fires.

local Players = game:GetService("Players")

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)
local Spawner = require(script.Parent.Spawner)
local Fusion = require(script.Parent.Fusion)
local Waves = require(script.Parent.Waves)

-- Base pads and spawn points, built in default.project.json.
local basePads = {}
local spawnPoints = {}
local BASE_COLORS = { "Red", "Blue", "Yellow", "Green" }
for i = 1, 4 do
	basePads[i] = workspace:WaitForChild("Base" .. tostring(i))
	spawnPoints[i] = workspace:WaitForChild("Spawn" .. tostring(i))
end

-- Slot offsets on a base pad: a 3-by-2 grid, 6 studs apart.
local function slotOffset(slot)
	local col = (slot - 1) % 3
	local row = math.floor((slot - 1) / 3)
	return Vector3.new((col - 1) * 6, 0, (row - 0.5) * 6)
end

-- Build the visible brainrot part that sits on a base slot.
local function makePlacedPart(state, def, slot)
	local pad = basePads[state.baseIndex]
	local part = Instance.new("Part")
	part.Name = "Placed_" .. def.id
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(3.5, 3.5, 3.5)
	part.Color = def.color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	local top = pad.Position + Vector3.new(0, pad.Size.Y / 2, 0)
	part.CFrame = CFrame.new(top + slotOffset(slot) + Vector3.new(0, 2, 0))
	part.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlacedLabel"
	gui.Size = UDim2.fromOffset(140, 40)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = def.name .. "  $" .. tostring(def.rate) .. "/s"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = gui
	gui.Parent = part
	return part
end

-- One place prompt per base pad. Only the pad's owner can use it.
local function makePlacePrompt(baseIndex)
	local pad = basePads[baseIndex]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlacePrompt"
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
		if state.baseIndex ~= baseIndex then
			PlayerData.Toast(state, "That is not your base! Your base is the one in your colour.")
			return
		end
		if #state.carried == 0 then
			PlayerData.Toast(state, "You are not carrying a brainrot. Catch one in the Wild Meadow first!")
			return
		end
		local id = state.carried[1]
		local def = Catalog.Get(id)
		local slot = PlayerData.TryPlace(state, id)
		if not slot then
			PlayerData.Toast(state, "Your base is full! Fuse brainrots in the Fusion Kitchen to make room.")
			return
		end
		local entry = state.placed[#state.placed]
		entry.part = makePlacedPart(state, def, slot)
		PlayerData.Sync(state)
		PlayerData.Toast(state, def.name .. " is on your base, earning $" .. tostring(def.rate) .. " every second!")
	end)
end

for i = 1, 4 do
	makePlacePrompt(i)
end

-- Hand a joining player the first free base, or the emptiest one.
local function assignBase()
	local taken = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerData.Get(player)
		if state then
			taken[state.baseIndex] = true
		end
	end
	for i = 1, 4 do
		if not taken[i] then
			return i
		end
	end
	return 1
end

local function onPlayerAdded(player)
	local baseIndex = assignBase()
	local state = PlayerData.Create(player, baseIndex, basePads[baseIndex])
	player:SetAttribute("BaseColor", BASE_COLORS[baseIndex])
	player.RespawnLocation = spawnPoints[baseIndex]
	PlayerData.Toast(state, "Welcome to Snacktopia! Your base is the " .. BASE_COLORS[baseIndex] .. " one. Catch a brainrot in the Wild Meadow, carry it home, and place it on your base.")
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		local spawn = spawnPoints[baseIndex]
		root.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 3, 0))
	end)
end

local function onPlayerRemoving(player)
	local state = PlayerData.Get(player)
	if state then
		for _, entry in ipairs(state.placed) do
			if entry.part and entry.part.Parent then
				entry.part:Destroy()
			end
		end
	end
	PlayerData.Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Income tick: every placed brainrot pays its rate, once a second.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = PlayerData.Get(player)
			if state then
				local income = PlayerData.Income(state)
				if income > 0 then
					PlayerData.AddMoney(state, income)
				end
				PlayerData.Sync(state)
			end
		end
	end
end)

Spawner.Start()
Fusion.Start()
Waves.Start(basePads)

print("Snacktopia server is running: catch, carry, place, fuse, and run home before the goblins come.")
