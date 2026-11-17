-- Snacktopia wild spawner: brainrots roam the Wild Meadow, each one a bright
-- bobbing creature with a buy prompt. Buying one is the first step of the
-- loop: catch it, carry it home, place it on your base.

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)

local Spawner = {}

-- Meadow spawn points. The world in default.project.json puts the meadow
-- (flowers, pond, bright grass) around these coordinates.
local SPAWN_POINTS = {
	Vector3.new(-50, 2, 70),
	Vector3.new(-20, 2, 90),
	Vector3.new(10, 2, 75),
	Vector3.new(40, 2, 95),
	Vector3.new(60, 2, 70),
	Vector3.new(-35, 2, 120),
	Vector3.new(15, 2, 125),
	Vector3.new(50, 2, 125),
}

local wild = {} -- array of { def, part, baseY, phase, pointIndex }
local freePoints = {}

local function makeLabel(def)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(160, 64)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = gui
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
	priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = def.rarity .. "  $" .. tostring(def.price) .. "  |  $" .. tostring(def.rate) .. "/s"
	priceLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
	priceLabel.TextStrokeTransparency = 0
	priceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.SourceSansBold
	priceLabel.Parent = gui
	return gui
end

local function makePrompt(def)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. def.name
	prompt.ObjectText = def.rarity .. " - $" .. tostring(def.price)
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	return prompt
end

-- Spawn one wild brainrot at a free point. Returns the wild record.
local function spawnOne()
	if #wild >= Catalog.MEADOW_CAP then
		return nil
	end
	if #freePoints == 0 then
		return nil
	end
	local pointIndex = table.remove(freePoints, 1)
	local point = SPAWN_POINTS[pointIndex]
	local def = Catalog.RandomCatchable()
	local part = Instance.new("Part")
	part.Name = "Wild_" .. def.id
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(4, 4, 4)
	part.Color = def.color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(point)
	part.Parent = workspace
	makeLabel(def).Parent = part
	local prompt = makePrompt(def)
	prompt.Parent = part
	local record = { def = def, part = part, baseY = point.Y, phase = math.random() * 6, pointIndex = pointIndex }
	prompt.Triggered:Connect(function(player)
		Spawner.TryBuy(player, record)
	end)
	table.insert(wild, record)
	return record
end

-- A player triggered a wild brainrot's buy prompt.
function Spawner.TryBuy(player, record)
	if not record.part or not record.part.Parent then
		return
	end
	local state = PlayerData.Get(player)
	if not state then
		return
	end
	local def = record.def
	if state.money < def.price then
		PlayerData.Toast(state, "Not enough money! " .. def.name .. " costs $" .. tostring(def.price) .. ".")
		return
	end
	if #state.carried >= Catalog.MAX_CARRY then
		PlayerData.Toast(state, "Your hands are full! Place a brainrot on your base first (max " .. tostring(Catalog.MAX_CARRY) .. ").")
		return
	end
	state.money = state.money - def.price
	PlayerData.TryCarry(state, def.id)
	PlayerData.Sync(state)
	PlayerData.Toast(state, "You caught " .. def.name .. "! Carry it home and place it on your base.")
	-- Remove this wild one and free its point for the next spawn.
	for i, entry in ipairs(wild) do
		if entry == record then
			table.remove(wild, i)
			break
		end
	end
	table.insert(freePoints, record.pointIndex)
	record.part:Destroy()
	-- A new one wanders in after a short, slightly random pause, so the
	-- meadow never refills on a metronome.
	task.delay(2 + math.random() * 3, function()
		spawnOne()
	end)
end

-- Keep the meadow full and make the wild brainrots bob and drift.
function Spawner.Start()
	for i = 1, #SPAWN_POINTS do
		table.insert(freePoints, i)
	end
	for _ = 1, Catalog.MEADOW_CAP do
		spawnOne()
	end
	task.spawn(function()
		while true do
			task.wait(0.15)
			local t = tick()
			for _, entry in ipairs(wild) do
				if entry.part and entry.part.Parent then
					local pos = entry.part.Position
					local bob = math.sin(t * 2 + entry.phase) * 0.6
					entry.part.CFrame = CFrame.new(pos.X, entry.baseY + 1 + bob, pos.Z)
				end
			end
			-- Top the meadow back up if anything was bought.
			while #wild < Catalog.MEADOW_CAP and #freePoints > 0 do
				spawnOne()
			end
		end
	end)
end

return Spawner
