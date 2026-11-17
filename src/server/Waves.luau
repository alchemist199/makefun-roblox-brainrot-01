-- Snacktopia Crumb Goblin waves: the threat. Every so often a warning sounds,
-- then goblins sweep in from the forest. They hunt players who are carrying
-- brainrots, and they raid bases whose owner is away. Standing on your own
-- base scares them off, so a wave is a race home with your catch.

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)

local Waves = {}

local WARNING_TIME = 10
local GOBLIN_SPEED = 14 -- studs per second
local GOBLIN_REACH = 4 -- steals a carried brainrot this close to a player
local BASE_RAID_RANGE = 8 -- steals from a base this close to its pad
local BASE_SAFE_RANGE = 14 -- owner standing this close to their pad scares goblins off

local goblins = {} -- array of { part, target }
local bases = {} -- array of base pad Parts, indexed by base index
local waveActive = false

local function makeGoblin(position)
	local part = Instance.new("Part")
	part.Name = "CrumbGoblin"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(3, 3, 3)
	part.Color = Color3.fromRGB(70, 30, 110)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(position)
	part.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Name = "GoblinLabel"
	gui.Size = UDim2.fromOffset(120, 30)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Crumb Goblin!"
	label.TextColor3 = Color3.fromRGB(255, 120, 120)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = gui
	gui.Parent = part
	return part
end

-- The nearest player who is carrying a brainrot, or nil.
local function nearestCarrier(fromPos)
	local best = nil
	local bestDist = nil
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local state = PlayerData.Get(player)
		if state and #state.carried > 0 then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local dist = (root.Position - fromPos).Magnitude
				if not bestDist or dist < bestDist then
					best = player
					bestDist = dist
				end
			end
		end
	end
	return best
end

-- The state that owns a base pad, or nil.
local function ownerOfBase(baseIndex)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local state = PlayerData.Get(player)
		if state and state.baseIndex == baseIndex then
			return state
		end
	end
	return nil
end

-- Is this player standing on their own base right now?
local function isOwnerHome(state)
	local character = state.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local pad = bases[state.baseIndex]
	if not pad then
		return false
	end
	return (root.Position - pad.Position).Magnitude < BASE_SAFE_RANGE
end

-- Steal the lowest-earning placed brainrot from a base, if it has any.
local function raidBase(state)
	if #state.placed == 0 then
		return false
	end
	local worstIndex = 1
	local worstRate = nil
	for i, entry in ipairs(state.placed) do
		local def = Catalog.Get(entry.id)
		local rate = def and def.rate or 0
		if not worstRate or rate < worstRate then
			worstRate = rate
			worstIndex = i
		end
	end
	local entry = state.placed[worstIndex]
	local part = entry.part
	if part and part.Parent then
		part:Destroy()
	end
	local stolenId = PlayerData.RemovePlaced(state, worstIndex)
	local def = Catalog.Get(stolenId)
	PlayerData.Sync(state)
	if def then
		PlayerData.Toast(state, "A Crumb Goblin stole your " .. def.name .. " from your base!")
	end
	return true
end

-- Move every goblin one step toward its target and resolve steals.
local function stepGoblins(dt)
	for i = #goblins, 1, -1 do
		local goblin = goblins[i]
		local part = goblin.part
		if not part or not part.Parent then
			table.remove(goblins, i)
		else
			local target = nil
			local carrier = nearestCarrier(part.Position)
			if carrier then
				local character = carrier.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					target = root.Position
					if (root.Position - part.Position).Magnitude < GOBLIN_REACH then
						local state = PlayerData.Get(carrier)
						if state and #state.carried > 0 then
							local stolenId = state.carried[1]
							PlayerData.RemoveCarried(state, stolenId)
							PlayerData.Sync(state)
							local def = Catalog.Get(stolenId)
							if def then
								PlayerData.Toast(state, "A Crumb Goblin stole your carried " .. def.name .. "! Run home faster next time.")
							end
						end
						part:Destroy()
						table.remove(goblins, i)
						target = nil
					end
				end
			end
			if target == nil and part.Parent then
				-- No carrier to chase: raid a random base.
				local baseIndex = math.random(#bases)
				local pad = bases[baseIndex]
				if pad then
					target = pad.Position
					if (pad.Position - part.Position).Magnitude < BASE_RAID_RANGE then
						local owner = ownerOfBase(baseIndex)
						if owner then
							if isOwnerHome(owner) then
								-- Owner is home: scared off, no steal.
								part:Destroy()
								table.remove(goblins, i)
								target = nil
							else
								raidBase(owner)
								part:Destroy()
								table.remove(goblins, i)
								target = nil
							end
						else
							part:Destroy()
							table.remove(goblins, i)
							target = nil
						end
					end
				end
			end
			if target ~= nil and part.Parent then
				local pos = part.Position
				local dir = target - pos
				local dist = dir.Magnitude
				if dist > 0.01 then
					local step = math.min(dist, GOBLIN_SPEED * dt)
					local next = pos + dir.Unit * step
					part.CFrame = CFrame.new(next.X, 2 + math.sin(tick() * 6) * 0.3, next.Z)
				end
			end
		end
	end
end

local function setWaveAttributes(stateName, timer)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		player:SetAttribute("WaveState", stateName)
		player:SetAttribute("WaveTimer", timer)
	end
end

local function spawnWave()
	local edges = {
		Vector3.new(-180, 2, 0),
		Vector3.new(180, 2, 0),
		Vector3.new(0, 2, -180),
		Vector3.new(0, 2, 180),
	}
	for _ = 1, Catalog.WAVE_GOBLINS do
		local edge = edges[math.random(#edges)]
		local part = makeGoblin(edge)
		table.insert(goblins, { part = part })
	end
end

local function clearGoblins()
	for _, goblin in ipairs(goblins) do
		if goblin.part and goblin.part.Parent then
			goblin.part:Destroy()
		end
	end
	goblins = {}
end

-- basePads: array of the four base pad Parts, indexed 1-4.
function Waves.Start(basePads)
	bases = basePads
	task.spawn(function()
		while true do
			-- Calm: count down to the next wave.
			local waitLeft = Catalog.WAVE_INTERVAL
			while waitLeft > 0 do
				setWaveAttributes("calm", waitLeft)
				task.wait(1)
				waitLeft = waitLeft - 1
			end
			-- Warning: 10 seconds to get home.
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				local warnState = PlayerData.Get(player)
				if warnState then
					PlayerData.Toast(warnState, "Goblin Wave in " .. tostring(WARNING_TIME) .. " seconds! Run home with your catch!")
				end
			end
			for left = WARNING_TIME, 1, -1 do
				setWaveAttributes("warning", left)
				task.wait(1)
			end
			-- The wave itself.
			waveActive = true
			spawnWave()
			local waveLeft = Catalog.WAVE_DURATION
			local lastStep = tick()
			while waveLeft > 0 do
				setWaveAttributes("wave", waveLeft)
				local now = tick()
				stepGoblins(now - lastStep)
				lastStep = now
				task.wait(0.2)
				waveLeft = waveLeft - 0.2
			end
			waveActive = false
			clearGoblins()
			setWaveAttributes("calm", Catalog.WAVE_INTERVAL)
		end
	end)
end

return Waves
