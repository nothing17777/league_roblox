-- Handles item purchasing, selling, and inventory management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemData = require(Shared.ItemData)
local Remotes = require(Shared.Remotes)

local ShopManager = {}

local MAX_ITEMS = 6

function ShopManager.getAvailableItems(pData)
	if not pData then return {} end
	local result = {}
	for id, item in pairs(ItemData.items) do
		table.insert(result, {id = id, name = item.name, price = item.price, stats = item.stats, icon = item.icon})
	end
	return result
end

function ShopManager.buyItem(player, pData, itemId)
	if not pData then return end
	local item = ItemData.items[itemId]
	if not item then
		warn("Unknown item: " .. tostring(itemId))
		return
	end

	if #pData.items >= MAX_ITEMS then
		Remotes.UpdateHUD:FireClient(player, {message = "Inventory full!"})
		return
	end

	if pData.gold < item.price then
		Remotes.UpdateHUD:FireClient(player, {message = "Not enough gold!"})
		return
	end

	pData.gold -= item.price
	table.insert(pData.items, itemId)

	-- Apply stats to character
	local model = workspace:FindFirstChild("Champion_" .. player.UserId)
	if model then
		ShopManager.applyItemStats(model, item.stats, 1)
	end

	Remotes.GoldUpdated:FireClient(player, pData.gold)
	Remotes.UpdateHUD:FireClient(player, {items = pData.items, gold = pData.gold})
end

function ShopManager.sellItem(player, pData, itemId)
	if not pData then return end
	local item = ItemData.items[itemId]
	if not item then return end

	for i, id in ipairs(pData.items) do
		if id == itemId then
			table.remove(pData.items, i)
			local sellValue = math.floor(item.price * 0.7)
			pData.gold += sellValue

			local model = workspace:FindFirstChild("Champion_" .. player.UserId)
			if model then
				ShopManager.applyItemStats(model, item.stats, -1)
			end

			Remotes.GoldUpdated:FireClient(player, pData.gold)
			Remotes.UpdateHUD:FireClient(player, {items = pData.items, gold = pData.gold})
			return
		end
	end
end

function ShopManager.applyItemStats(model, stats, sign)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if stats.hp then
		humanoid.MaxHealth += stats.hp * sign
		humanoid.Health = math.min(humanoid.Health + stats.hp * sign, humanoid.MaxHealth)
	end
	-- AD, AP, armor, etc. are stored in the player's combat stats table
	-- and read dynamically by ChampionManager when calculating damage
end

return ShopManager
