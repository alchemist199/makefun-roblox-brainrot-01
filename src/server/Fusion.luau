-- The Fusion Kitchen: carry any two brainrots to the cauldron and fuse them
-- into a Mythic hybrid that never roams the meadow.

local Catalog = require(script.Parent.Catalog)
local PlayerData = require(script.Parent.PlayerData)

local Fusion = {}

local function buildSign(cauldron)
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(340, 150)
	board.StudsOffset = Vector3.new(0, 7, 0)
	board.AlwaysOnTop = true
	board.Parent = cauldron
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
	frame.BackgroundTransparency = 0.2
	frame.Parent = board
	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(0, 4)
	title.Size = UDim2.new(1, 0, 0, 26)
	title.BackgroundTransparency = 1
	title.Text = "FUSION KITCHEN - fuse 2, get 1 hybrid!"
	title.TextColor3 = Color3.fromRGB(255, 220, 60)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = frame
	for i, recipe in ipairs(Catalog.Recipes) do
		local line = Instance.new("TextLabel")
		line.Position = UDim2.fromOffset(6, 30 + (i - 1) * 36)
		line.Size = UDim2.new(1, -12, 0, 34)
		line.BackgroundTransparency = 1
		line.Text = recipe.Label
		line.TextColor3 = Color3.fromRGB(255, 255, 255)
		line.Font = Enum.Font.Gotham
		line.TextScaled = true
		line.TextWrapped = true
		line.Parent = frame
	end
end

local function onFuse(player)
	local state = PlayerData.Get(player)
	if not state then
		return
	end
	if #state.Carried < 2 then
		PlayerData.Toast(state, string.format("You carry %d brainrot(s). You need 2 to fuse!", #state.Carried))
		return
	end
	local firstId = state.Carried[1]
	local secondId = state.Carried[2]
	local recipe = Catalog.FindFusion(firstId, secondId)
	if not recipe then
		local firstDef = Catalog.GetById(firstId)
		local secondDef = Catalog.GetById(secondId)
		local firstName = firstDef and firstDef.Name or firstId
		local secondName = secondDef and secondDef.Name or secondId
		PlayerData.Toast(state, string.format("%s and %s do not fuse. Read the recipes on the wall!", firstName, secondName))
		return
	end
	local hybrid = Catalog.GetById(recipe.Result)
	PlayerData.RemoveCarried(state, firstId)
	PlayerData.RemoveCarried(state, secondId)
	PlayerData.TryCarry(state, recipe.Result)
	state.Hybrids += 1
	PlayerData.Sync(state)
	PlayerData.Toast(state, string.format("FUSION! %s is yours - $%d/s. Place it on your base!", hybrid.Name, hybrid.Rate))
	if #state.Placed >= Catalog.BASE_SLOTS then
		PlayerData.Toast(state, "Your base is full! Place the hybrid after fusing or selling room by fusing more.")
	end
	if state.Hybrids >= Catalog.HYBRID_COUNT then
		PlayerData.Toast(state, string.format("SNACKTOPIA MASTER! You fused all %d hybrids!", Catalog.HYBRID_COUNT))
	end
end

function Fusion.Start()
	local kitchen = workspace:WaitForChild("FusionKitchen")
	local cauldron = kitchen:WaitForChild("Cauldron")
	buildSign(cauldron)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Fuse carried brainrots"
	prompt.ObjectText = "Fusion Kitchen"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = cauldron
	prompt.Triggered:Connect(onFuse)
end

return Fusion
