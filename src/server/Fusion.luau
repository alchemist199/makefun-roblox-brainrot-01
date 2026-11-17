-- Snacktopia Fusion Kitchen: the game's one new mechanic. Carry two
-- brainrots to the cauldron and fuse them into a rarer hybrid. Fusing is how
-- you climb past the shop: hybrids never roam the meadow, and a fused
-- brainrot earns far more than either ingredient alone.

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)

local Fusion = {}

-- Build the recipe sign that hangs over the cauldron, from the catalog, so
-- the recipes on the wall are always the recipes the code knows.
local function makeSign(cauldron)
	local gui = Instance.new("BillboardGui")
	gui.Name = "FusionSign"
	gui.Size = UDim2.fromOffset(340, 150)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = true
	local frame = Instance.new("Frame")
	frame.Name = "Sign"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Text = "FUSION KITCHEN - fuse 2, get 1 hybrid!"
	title.TextColor3 = Color3.fromRGB(255, 220, 90)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = frame
	local y = 30
	for _, recipe in ipairs(Catalog.Fusions) do
		local line = Instance.new("TextLabel")
		line.Name = "Recipe"
		line.Position = UDim2.new(0, 6, 0, y)
		line.Size = UDim2.new(1, -12, 0, 34)
		line.BackgroundTransparency = 1
		line.Text = recipe.label
		line.TextColor3 = Color3.fromRGB(255, 255, 255)
		line.TextScaled = true
		line.TextWrapped = true
		line.Font = Enum.Font.SourceSans
		line.Parent = frame
		y = y + 36
	end
	gui.Parent = cauldron
end

-- A player triggered the cauldron's fuse prompt.
local function onFuse(player)
	local state = PlayerData.Get(player)
	if not state then
		return
	end
	if #state.carried < 2 then
		PlayerData.Toast(state, "Bring TWO brainrots to fuse! You are carrying " .. tostring(#state.carried) .. ".")
		return
	end
	local idA = state.carried[1]
	local idB = state.carried[2]
	local recipe = Catalog.FindFusion(idA, idB)
	if not recipe then
		local defA = Catalog.Get(idA)
		local defB = Catalog.Get(idB)
		local nameA = defA and defA.name or idA
		local nameB = defB and defB.name or idB
		PlayerData.Toast(state, nameA .. " + " .. nameB .. " do not fuse. Read the recipes on the wall!")
		return
	end
	-- Take both ingredients, hand back the hybrid.
	PlayerData.RemoveCarried(state, idA)
	PlayerData.RemoveCarried(state, idB)
	PlayerData.TryCarry(state, recipe.result)
	state.hybrids = state.hybrids + 1
	PlayerData.Sync(state)
	local hybrid = Catalog.Get(recipe.result)
	local hybridName = hybrid and hybrid.name or recipe.result
	PlayerData.Toast(state, "FUSION! " .. hybridName .. " is yours - $" .. tostring(hybrid.rate) .. "/s. Place it on your base!")
	if #state.placed >= Catalog.BASE_SLOTS then
		PlayerData.Toast(state, "Your base is full! Place the hybrid after you fuse or sell room by fusing more.")
	end
	if state.hybrids >= #Catalog.Fusions then
		PlayerData.Toast(state, "SNACKTOPIA MASTER! You fused all " .. tostring(#Catalog.Fusions) .. " hybrids!")
	end
end

function Fusion.Start()
	local kitchen = workspace:WaitForChild("FusionKitchen")
	local cauldron = kitchen:WaitForChild("Cauldron")
	makeSign(cauldron)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FusePrompt"
	prompt.ActionText = "Fuse carried brainrots"
	prompt.ObjectText = "Fusion Kitchen"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = cauldron
	prompt.Triggered:Connect(onFuse)
end

return Fusion
