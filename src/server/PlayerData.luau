-- Snacktopia player state: money, carried brainrots, placed brainrots, and
-- the attributes the client HUD reads. The server is the only writer; the
-- client never trusts its own copy of these numbers.

local Catalog = require(script.Parent.Catalog)

local PlayerData = {}

local states = {}

-- Create the state for a player who just joined. baseIndex picks one of the
-- four base pads (1-4) and basePart is that pad's Part in the world.
function PlayerData.Create(player, baseIndex, basePart)
	local state = {
		player = player,
		money = Catalog.START_MONEY,
		carried = {}, -- array of brainrot ids, at most Catalog.MAX_CARRY
		placed = {}, -- array of { id = brainrot id, slot = slot number, part = Part or nil }
		hybrids = 0,
		baseIndex = baseIndex,
		basePart = basePart,
		toastId = 0,
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

-- Money earned per second by everything on this player's base.
function PlayerData.Income(state)
	local total = 0
	for _, entry in ipairs(state.placed) do
		local def = Catalog.Get(entry.id)
		if def then
			total = total + def.rate
		end
	end
	return total
end

function PlayerData.AddMoney(state, amount)
	state.money = state.money + amount
end

-- Carry a brainrot id. Returns true when there is a free carry slot.
function PlayerData.TryCarry(state, id)
	if #state.carried >= Catalog.MAX_CARRY then
		return false
	end
	table.insert(state.carried, id)
	return true
end

-- Place a carried brainrot on the player's base. Returns the slot number, or
-- nil when the base is full or the brainrot is not being carried.
function PlayerData.TryPlace(state, id)
	if #state.placed >= Catalog.BASE_SLOTS then
		return nil
	end
	local carryIndex = nil
	for i, carriedId in ipairs(state.carried) do
		if carriedId == id then
			carryIndex = i
			break
		end
	end
	if not carryIndex then
		return nil
	end
	table.remove(state.carried, carryIndex)
	local used = {}
	for _, entry in ipairs(state.placed) do
		used[entry.slot] = true
	end
	local slot = 1
	while used[slot] do
		slot = slot + 1
	end
	table.insert(state.placed, { id = id, slot = slot, part = nil })
	return slot
end

-- Take a placed brainrot away (a goblin stole it). Returns its id or nil.
function PlayerData.RemovePlaced(state, index)
	local entry = state.placed[index]
	if not entry then
		return nil
	end
	table.remove(state.placed, index)
	return entry.id
end

-- Take a carried brainrot away (a goblin stole it off the player).
function PlayerData.RemoveCarried(state, id)
	for i, carriedId in ipairs(state.carried) do
		if carriedId == id then
			table.remove(state.carried, i)
			return true
		end
	end
	return false
end

-- Names of the brainrots the player is carrying, for the HUD.
function PlayerData.CarryingText(state)
	local names = {}
	for _, id in ipairs(state.carried) do
		local def = Catalog.Get(id)
		if def then
			table.insert(names, def.name)
		end
	end
	if #names == 0 then
		return ""
	end
	return table.concat(names, " + ")
end

-- Push the state into player attributes so the client HUD can read it.
function PlayerData.Sync(state)
	local player = state.player
	player:SetAttribute("Money", state.money)
	player:SetAttribute("Income", PlayerData.Income(state))
	player:SetAttribute("Carrying", PlayerData.CarryingText(state))
	player:SetAttribute("CarriedCount", #state.carried)
	player:SetAttribute("PlacedCount", #state.placed)
	player:SetAttribute("Hybrids", state.hybrids)
	player:SetAttribute("Goal", "Fuse all " .. tostring(Catalog.HYBRID_COUNT) .. " hybrids: " .. tostring(state.hybrids) .. "/" .. tostring(Catalog.HYBRID_COUNT))
end

-- Show a short message on the player's screen.
function PlayerData.Toast(state, message)
	state.toastId = state.toastId + 1
	state.player:SetAttribute("Toast", message)
	state.player:SetAttribute("ToastId", state.toastId)
end

return PlayerData
