-- Per-player state for Snacktopia: money, carried and placed brainrots, hybrids
-- fused, and the base a player owns. The client never keeps its own copy of
-- these numbers; everything it shows comes from the attributes synced here.

local Catalog = require(script.Parent.Catalog)

local PlayerData = {}

local states = {}

function PlayerData.Create(player, baseIndex, basePart)
	local state = {
		Player = player,
		Money = Catalog.START_MONEY,
		Carried = {},
		Placed = {},
		Hybrids = 0,
		BaseIndex = baseIndex,
		BasePart = basePart,
		ToastCounter = 0,
	}
	states[player] = state
	PlayerData.Sync(state)
	return state
end

function PlayerData.Get(player)
	return states[player]
end

function PlayerData.Remove(player)
	states[player] = nil
end

function PlayerData.Income(state)
	local total = 0
	for _, placed in ipairs(state.Placed) do
		local def = Catalog.GetById(placed.Id)
		if def then
			total += def.Rate
		end
	end
	return total
end

function PlayerData.AddMoney(state, amount)
	state.Money += amount
end

function PlayerData.TryCarry(state, id)
	if #state.Carried >= Catalog.MAX_CARRY then
		return false
	end
	table.insert(state.Carried, id)
	return true
end

function PlayerData.TryPlace(state, id)
	for i, carriedId in ipairs(state.Carried) do
		if carriedId == id then
			if #state.Placed >= Catalog.BASE_SLOTS then
				return nil
			end
			local taken = {}
			for _, placed in ipairs(state.Placed) do
				taken[placed.Slot] = true
			end
			local slot = 1
			while taken[slot] do
				slot += 1
			end
			table.remove(state.Carried, i)
			local entry = { Id = id, Slot = slot, Part = nil }
			table.insert(state.Placed, entry)
			return slot
		end
	end
	return nil
end

function PlayerData.RemovePlaced(state, index)
	local entry = state.Placed[index]
	if not entry then
		return nil
	end
	table.remove(state.Placed, index)
	return entry.Id
end

function PlayerData.RemoveCarried(state, id)
	for i, carriedId in ipairs(state.Carried) do
		if carriedId == id then
			table.remove(state.Carried, i)
			return true
		end
	end
	return false
end

function PlayerData.CarryingText(state)
	local names = {}
	for _, id in ipairs(state.Carried) do
		local def = Catalog.GetById(id)
		if def then
			table.insert(names, def.Name)
		end
	end
	return table.concat(names, " + ")
end

function PlayerData.Sync(state)
	local player = state.Player
	player:SetAttribute("Money", state.Money)
	player:SetAttribute("Income", PlayerData.Income(state))
	player:SetAttribute("Carrying", PlayerData.CarryingText(state))
	player:SetAttribute("CarriedCount", #state.Carried)
	player:SetAttribute("PlacedCount", #state.Placed)
	player:SetAttribute("Hybrids", state.Hybrids)
	player:SetAttribute("Goal", string.format("Fuse all %d hybrids: %d/%d", Catalog.HYBRID_COUNT, state.Hybrids, Catalog.HYBRID_COUNT))
end

function PlayerData.Toast(state, message)
	state.ToastCounter += 1
	state.Player:SetAttribute("Toast", message)
	state.Player:SetAttribute("ToastId", state.ToastCounter)
end

return PlayerData
