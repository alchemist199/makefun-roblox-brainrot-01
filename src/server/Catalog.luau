-- Snacktopia catalog: every brainrot type, its rarity, its money rate, its
-- price, its colour, and the fusion recipes. The server owns this data; the
-- client only ever sees names and numbers through player attributes.

local Catalog = {}

-- Game tuning.
Catalog.START_MONEY = 100
Catalog.BASE_SLOTS = 6
Catalog.MAX_CARRY = 2
Catalog.WAVE_INTERVAL = 100 -- seconds between Crumb Goblin waves
Catalog.WAVE_DURATION = 30 -- seconds a wave lasts
Catalog.WAVE_GOBLINS = 4
Catalog.MEADOW_CAP = 8 -- wild brainrots alive at once

-- Every brainrot in the game. catchable ones roam the Wild Meadow; hybrids
-- (rarity Mythic) only ever come out of the Fusion Kitchen.
Catalog.Brainrots = {
	{ id = "soggy", name = "Soggy Cereal Knight", rarity = "Common", rate = 2, price = 50, weight = 30, catchable = true, color = Color3.fromRGB(255, 200, 90) },
	{ id = "noodle", name = "Noodle Arms Ned", rarity = "Common", rate = 3, price = 80, weight = 26, catchable = true, color = Color3.fromRGB(255, 150, 80) },
	{ id = "toaster", name = "DJ Toaster", rarity = "Uncommon", rate = 6, price = 150, weight = 16, catchable = true, color = Color3.fromRGB(120, 180, 255) },
	{ id = "pickle", name = "Professor Pickle", rarity = "Uncommon", rate = 8, price = 220, weight = 12, catchable = true, color = Color3.fromRGB(120, 220, 90) },
	{ id = "boba", name = "Baron Bubble Tea", rarity = "Rare", rate = 15, price = 400, weight = 7, catchable = true, color = Color3.fromRGB(220, 130, 220) },
	{ id = "couch", name = "Queen Couch Potato", rarity = "Rare", rate = 20, price = 550, weight = 5, catchable = true, color = Color3.fromRGB(200, 90, 120) },
	{ id = "leftovers", name = "Sir Lancelot Leftovers", rarity = "Epic", rate = 35, price = 900, weight = 2, catchable = true, color = Color3.fromRGB(255, 220, 60) },
	{ id = "ketchup", name = "Captain Ketchup", rarity = "Epic", rate = 40, price = 1100, weight = 1, catchable = true, color = Color3.fromRGB(230, 50, 50) },
	{ id = "grandnoodle", name = "The Grand Noodle", rarity = "Legendary", rate = 60, price = 1500, weight = 1, catchable = true, color = Color3.fromRGB(255, 240, 150) },
	{ id = "soggybeats", name = "DJ Soggy Beats", rarity = "Mythic", rate = 50, price = 0, weight = 0, catchable = false, color = Color3.fromRGB(255, 170, 40) },
	{ id = "bobapickle", name = "Boba Pickle Baron", rarity = "Mythic", rate = 90, price = 0, weight = 0, catchable = false, color = Color3.fromRGB(180, 255, 120) },
	{ id = "couchnoodle", name = "Couch Noodle Supreme", rarity = "Mythic", rate = 75, price = 0, weight = 0, catchable = false, color = Color3.fromRGB(255, 120, 200) },
}

-- Fusion recipes: two brainrots in, one hybrid out. Order does not matter.
-- This is the game's one new mechanic: fuse, do not just collect.
Catalog.Fusions = {
	{ a = "soggy", b = "toaster", result = "soggybeats", label = "Soggy Cereal Knight + DJ Toaster = DJ Soggy Beats ($50/s)" },
	{ a = "pickle", b = "boba", result = "bobapickle", label = "Professor Pickle + Baron Bubble Tea = Boba Pickle Baron ($90/s)" },
	{ a = "noodle", b = "couch", result = "couchnoodle", label = "Noodle Arms Ned + Queen Couch Potato = Couch Noodle Supreme ($75/s)" },
}

local ById = {}
for _, def in ipairs(Catalog.Brainrots) do
	ById[def.id] = def
end

-- How many hybrids exist: the goal is to fuse all of them.
Catalog.HYBRID_COUNT = #Catalog.Fusions

-- True when this brainrot id is a fusion-only hybrid (never roams the meadow).
function Catalog.IsHybrid(id)
	local def = ById[id]
	return def ~= nil and not def.catchable
end

function Catalog.Get(id)
	return ById[id]
end

-- Find the fusion recipe for a pair of brainrot ids, either order.
function Catalog.FindFusion(idA, idB)
	for _, recipe in ipairs(Catalog.Fusions) do
		if (recipe.a == idA and recipe.b == idB) or (recipe.a == idB and recipe.b == idA) then
			return recipe
		end
	end
	return nil
end

-- Pick a random catchable brainrot, weighted so commons show up most.
function Catalog.RandomCatchable()
	local total = 0
	for _, def in ipairs(Catalog.Brainrots) do
		if def.catchable then
			total = total + def.weight
		end
	end
	local roll = math.random(total)
	local running = 0
	for _, def in ipairs(Catalog.Brainrots) do
		if def.catchable then
			running = running + def.weight
			if roll <= running then
				return def
			end
		end
	end
	return Catalog.Brainrots[1]
end

-- Short rarity colour for HUD text.
function Catalog.RarityColor(rarity)
	if rarity == "Common" then
		return Color3.fromRGB(220, 220, 220)
	elseif rarity == "Uncommon" then
		return Color3.fromRGB(120, 220, 120)
	elseif rarity == "Rare" then
		return Color3.fromRGB(120, 170, 255)
	elseif rarity == "Epic" then
		return Color3.fromRGB(200, 120, 255)
	elseif rarity == "Legendary" then
		return Color3.fromRGB(255, 210, 60)
	else
		return Color3.fromRGB(255, 90, 200)
	end
end

return Catalog
