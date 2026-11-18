-- Wild brainrots in the Wild Meadow: they roam (well, bob), show a buy prompt,
-- and get carried home. The meadow is kept topped up to its cap.

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)

local Spawner = {}

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

local wild = {}
local freePoints = {}

local function buildLabel(def)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(140, 40)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = gui
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Position = UDim2.fromScale(0, 0.5)
	infoLabel.Size = UDim2.fromScale(1, 0.5)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = string.format("%s - $%d - $%d/s", def.Rarity, def.Price, def.Rate)
	infoLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
	infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextStrokeTransparency = 0
	infoLabel.Parent = gui
	return gui
end

local function onBuy(player, record)
	if not record.Part or not record.Part.Parent then
		return
	end
	local state = PlayerData.Get(player)
	if not state then
		return
	end
	local def = record.Def
	if state.Money < def.Price then
		PlayerData.Toast(state, string.format("That costs $%d!", def.Price))
		return
	end
	if #state.Carried >= Catalog.MAX_CARRY then
		PlayerData.Toast(state, "Your hands are full! Place one first (max 2).")
		return
	end
	PlayerData.AddMoney(state, -def.Price)
	PlayerData.TryCarry(state, def.Id)
	PlayerData.Sync(state)
	PlayerData.Toast(state, string.format("You caught %s! Carry it home and place it on your base.", def.Name))
	for i, other in ipairs(wild) do
		if other == record then
			table.remove(wild, i)
			break
		end
	end
	table.insert(freePoints, record.PointIndex)
	record.Part:Destroy()
	task.delay(math.random(2, 5), function()
		Spawner.SpawnOne()
	end)
end

function Spawner.SpawnOne()
	if #wild >= Catalog.MEADOW_CAP then
		return
	end
	if #freePoints == 0 then
		return
	end
	local pointIndex = table.remove(freePoints, 1)
	local def = Catalog.RandomCatchable()
	local point = SPAWN_POINTS[pointIndex]
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(4, 4, 4)
	ball.Color = def.Color
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = false
	ball.Position = point
	ball.Name = def.Name
	ball.Parent = workspace
	buildLabel(def).Parent = ball
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. def.Name
	prompt.ObjectText = string.format("%s - $%d", def.Rarity, def.Price)
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = ball
	local record = {
		Def = def,
		Part = ball,
		BaseY = point.Y,
		Phase = math.random() * math.pi * 2,
		PointIndex = pointIndex,
	}
	prompt.Triggered:Connect(function(player)
		onBuy(player, record)
	end)
	table.insert(wild, record)
end

function Spawner.Start()
	for i = 1, #SPAWN_POINTS do
		table.insert(freePoints, i)
	end
	for _ = 1, Catalog.MEADOW_CAP do
		Spawner.SpawnOne()
	end
	task.spawn(function()
		while true do
			task.wait(0.15)
			local now = os.clock()
			for _, record in ipairs(wild) do
				if record.Part and record.Part.Parent then
					local bob = math.sin(now * 2 + record.Phase) * 0.6
					record.Part.Position = Vector3.new(
						record.Part.Position.X,
						record.BaseY + 1 + bob,
						record.Part.Position.Z
					)
				end
			end
			if #wild < Catalog.MEADOW_CAP and #freePoints > 0 then
				Spawner.SpawnOne()
			end
		end
	end)
end

return Spawner
