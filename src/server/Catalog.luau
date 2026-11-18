-- Snacktopia catalog: tuning numbers, the brainrot ladder, and the fusion recipes.
-- Every other server module reads its numbers from here, so a balance change
-- only ever touches this one file.

local Catalog = {}

Catalog.START_MONEY = 100
Catalog.BASE_SLOTS = 6
Catalog.MAX_CARRY = 2
Catalog.WAVE_INTERVAL = 100
Catalog.WAVE_DURATION = 30
Catalog.GOBLINS_PER_WAVE = 4
Catalog.MEADOW_CAP = 8

-- id, name, rarity, dollars per second, buy price, spawn weight, catchable, colour
Catalog.Brainrots = {
	{ Id = "soggy", Name = "Soggy Cereal Knight", Rarity = "Common", Rate = 2, Price = 50, Weight = 30, Catchable = true, Color = Color3.fromRGB(255, 200, 90) },
	{ Id = "noodle", Name = "Noodle Arms Ned", Rarity = "Common", Rate = 3, Price = 80, Weight = 26, Catchable = true, Color = Color3.fromRGB(255, 150, 80) },
	{ Id = "toaster", Name = "DJ Toaster", Rarity = "Uncommon", Rate = 6, Price = 150, Weight = 16, Catchable = true, Color = Color3.fromRGB(120, 180, 255) },
	{ Id = "pickle", Name = "Professor Pickle", Rarity = "Uncommon", Rate = 8, Price = 220, Weight = 12, Catchable = true, Color = Color3.fromRGB(120, 220, 90) },
	{ Id = "boba", Name = "Baron Bubble Tea", Rarity = "Rare", Rate = 15, Price = 400, Weight = 7, Catchable = true, Color = Color3.fromRGB(220, 130, 220) },
	{ Id = "couch", Name = "Queen Couch Potato", Rarity = "Rare", Rate = 20, Price = 550, Weight = 5, Catchable = true, Color = Color3.fromRGB(200, 90, 120) },
	{ Id = "leftovers", Name = "Sir Lancelot Leftovers", Rarity = "Epic", Rate = 35, Price = 900, Weight = 2, Catchable = true, Color = Color3.fromRGB(255, 220, 60) },
	{ Id = "ketchup", Name = "Captain Ketchup", Rarity = "Epic", Rate = 40, Price = 1100, Weight = 1, Catchable = true, Color = Color3.fromRGB(230, 50, 50) },
	{ Id = "grandnoodle", Name = "The Grand Noodle", Rarity = "Legendary", Rate = 60, Price = 1500, Weight = 1, Catchable = true, Color = Color3.fromRGB(255, 240, 150) },
	{ Id = "soggybeats", Name = "DJ Soggy Beats", Rarity = "Mythic", Rate = 50, Price = 0, Weight = 0, Catchable = false, Color = Color3.fromRGB(255, 170, 40) },
	{ Id = "bobapickle", Name = "Boba Pickle Baron", Rarity = "Mythic", Rate = 90, Price = 0, Weight = 0, Catchable = false, Color = Color3.fromRGB(180, 255, 120) },
	{ Id = "couchnoodle", Name = "Couch Noodle Supreme", Rarity = "Mythic", Rate = 75, Price = 0, Weight = 0, Catchable = false, Color = Color3.fromRGB(255, 120, 200) },
}

-- Each recipe fuses two carried brainrots into one Mythic hybrid.
Catalog.Recipes = {
	{ A = "soggy", B = "toaster", Result = "soggybeats", Label = "Soggy Cereal Knight + DJ Toaster = DJ Soggy Beats ($50/s)" },
	{ A = "pickle", B = "boba", Result = "bobapickle", Label = "Professor Pickle + Baron Bubble Tea = Boba Pickle Baron ($90/s)" },
	{ A = "noodle", B = "couch", Result = "couchnoodle", Label = "Noodle Arms Ned + Queen Couch Potato = Couch Noodle Supreme ($75/s)" },
}

Catalog.HYBRID_COUNT = 3

local byId = {}
for _, entry in ipairs(Catalog.Brainrots) do
	byId[entry.Id] = entry
end

function Catalog.GetById(id)
	return byId[id]
end

function Catalog.IsHybrid(id)
	local entry = byId[id]
	return entry ~= nil and not entry.Catchable
end

function Catalog.FindFusion(firstId, secondId)
	for _, recipe in ipairs(Catalog.Recipes) do
		local forward = recipe.A == firstId and recipe.B == secondId
		local backward = recipe.A == secondId and recipe.B == firstId
		if forward or backward then
			return recipe
		end
	end
	return nil
end

function Catalog.RandomCatchable()
	local total = 0
	for _, entry in ipairs(Catalog.Brainrots) do
		if entry.Catchable then
			total += entry.Weight
		end
	end
	local roll = math.random(1, total)
	local running = 0
	for _, entry in ipairs(Catalog.Brainrots) do
		if entry.Catchable then
			running += entry.Weight
			if running >= roll then
				return entry
			end
		end
	end
	return Catalog.Brainrots[1]
end

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
