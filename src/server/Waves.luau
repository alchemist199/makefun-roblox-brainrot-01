-- Crumb Goblin waves: every ~100 seconds a wave sweeps in. Goblins steal
-- carried brainrots on touch and raid bases whose owner is away; standing on
-- your own base scares them off.

local Players = game:GetService("Players")

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)

local Waves = {}

local WARNING_TIME = 10
local GOBLIN_SPEED = 14
local STEAL_RANGE = 4
local RAID_RANGE = 8
local SAFE_RANGE = 14

local EDGE_POINTS = {
	Vector3.new(-180, 2, 0),
	Vector3.new(180, 2, 0),
	Vector3.new(0, 2, -180),
	Vector3.new(0, 2, 180),
}

local goblins = {}

local function setWaveAttributes(stateName, secondsLeft)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("WaveState", stateName)
		player:SetAttribute("WaveTimer", secondsLeft)
	end
end

local function makeGoblin()
	local edge = EDGE_POINTS[math.random(1, #EDGE_POINTS)]
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(3, 3, 3)
	ball.Color = Color3.fromRGB(70, 30, 110)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = false
	ball.Position = edge
	ball.Name = "Crumb Goblin"
	ball.Parent = workspace
	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(120, 30)
	label.StudsOffset = Vector3.new(0, 2.5, 0)
	label.AlwaysOnTop = true
	label.Parent = ball
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "Crumb Goblin!"
	text.TextColor3 = Color3.fromRGB(255, 60, 60)
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextStrokeTransparency = 0
	text.Parent = label
	local goblin = { Part = ball, TargetPad = nil }
	table.insert(goblins, goblin)
	return goblin
end

local function destroyGoblin(goblin)
	for i, other in ipairs(goblins) do
		if other == goblin then
			table.remove(goblins, i)
			break
		end
	end
	if goblin.Part then
		goblin.Part:Destroy()
	end
end

local function ownerIsHome(state)
	if not state or not state.BasePart then
		return false
	end
	local character = state.Player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	return (root.Position - state.BasePart.Position).Magnitude <= SAFE_RANGE
end

local function raidBase(goblin, pad, pads)
	local ownerState = nil
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerData.Get(player)
		if state and state.BasePart == pad then
			ownerState = state
			break
		end
	end
	if not ownerState then
		destroyGoblin(goblin)
		return
	end
	if ownerIsHome(ownerState) then
		destroyGoblin(goblin)
		return
	end
	if #ownerState.Placed == 0 then
		destroyGoblin(goblin)
		return
	end
	local worstIndex = 1
	local worstRate = math.huge
	for i, placed in ipairs(ownerState.Placed) do
		local def = Catalog.GetById(placed.Id)
		local rate = def and def.Rate or 0
		if rate < worstRate then
			worstRate = rate
			worstIndex = i
		end
	end
	local stolen = ownerState.Placed[worstIndex]
	local stolenDef = Catalog.GetById(stolen.Id)
	if stolen.Part then
		stolen.Part:Destroy()
	end
	PlayerData.RemovePlaced(ownerState, worstIndex)
	PlayerData.Sync(ownerState)
	if stolenDef then
		PlayerData.Toast(ownerState, string.format("A goblin stole %s from your base!", stolenDef.Name))
	end
	destroyGoblin(goblin)
end

local function nearestCarrier(goblin)
	local bestPlayer = nil
	local bestDistance = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerData.Get(player)
		if state and #state.Carried > 0 and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local distance = (root.Position - goblin.Part.Position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					bestPlayer = player
				end
			end
		end
	end
	return bestPlayer, bestDistance
end

local function stepGoblins(pads, dt)
	for i = #goblins, 1, -1 do
		local goblin = goblins[i]
		if not goblin.Part or not goblin.Part.Parent then
			table.remove(goblins, i)
		else
			local carrier, distance = nearestCarrier(goblin)
			if carrier then
				local root = carrier.Character:FindFirstChild("HumanoidRootPart")
				local direction = (root.Position - goblin.Part.Position)
				local length = direction.Magnitude
				if length > 0 then
					local step = direction.Unit * GOBLIN_SPEED * dt
					local bob = math.sin(os.clock() * 6) * 0.3
					goblin.Part.Position = goblin.Part.Position + Vector3.new(step.X, bob * dt, step.Z)
				end
				if distance <= STEAL_RANGE then
					local state = PlayerData.Get(carrier)
					if state and #state.Carried > 0 then
						local stolenId = state.Carried[1]
						local stolenDef = Catalog.GetById(stolenId)
						PlayerData.RemoveCarried(state, stolenId)
						PlayerData.Sync(state)
						if stolenDef then
							PlayerData.Toast(state, string.format("A goblin stole your %s! Run home faster next time!", stolenDef.Name))
						end
					end
					destroyGoblin(goblin)
				end
			else
				if not goblin.TargetPad or not goblin.TargetPad.Parent then
					goblin.TargetPad = pads[math.random(1, #pads)]
				end
				local pad = goblin.TargetPad
				local toPad = pad.Position - goblin.Part.Position
				local padDistance = toPad.Magnitude
				if padDistance <= RAID_RANGE then
					raidBase(goblin, pad, pads)
				elseif padDistance > 0 then
					local step = toPad.Unit * GOBLIN_SPEED * dt
					local bob = math.sin(os.clock() * 6) * 0.3
					goblin.Part.Position = goblin.Part.Position + Vector3.new(step.X, bob * dt, step.Z)
				end
			end
		end
	end
end

function Waves.Start(pads)
	task.spawn(function()
		while true do
			for left = Catalog.WAVE_INTERVAL, 1, -1 do
				setWaveAttributes("calm", left)
				task.wait(1)
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local state = PlayerData.Get(player)
				if state then
					PlayerData.Toast(state, "A goblin wave comes in 10 seconds! Run home with your catch!")
				end
			end
			for left = WARNING_TIME, 1, -1 do
				setWaveAttributes("warning", left)
				task.wait(1)
			end
			for _ = 1, Catalog.GOBLINS_PER_WAVE do
				makeGoblin()
			end
			local elapsed = 0
			while elapsed < Catalog.WAVE_DURATION do
				setWaveAttributes("wave", Catalog.WAVE_DURATION - math.floor(elapsed))
				stepGoblins(pads, 0.2)
				task.wait(0.2)
				elapsed += 0.2
			end
			for i = #goblins, 1, -1 do
				local goblin = goblins[i]
				if goblin.Part then
					goblin.Part:Destroy()
				end
				table.remove(goblins, i)
			end
		end
	end)
end

return Waves
