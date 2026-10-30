-- Handles champion stats, leveling, damage, and death/respawn

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local ChampionData = require(Shared.ChampionData)
local Remotes = require(Shared.Remotes)

local ChampionManager = {}

-- Compute stat at a given level (linear scaling)
function ChampionManager.getStat(alias, statName, level)
	local base = ChampionData.stats[alias]
	if not base then return 0 end
	level = math.clamp(level or 1, 1, Constants.MAX_LEVEL)
	if statName == "hp" then
		return base.hp + base.hpPerLvl * (level - 1)
	elseif statName == "ad" then
		return base.ad + base.adPerLvl * (level - 1)
	elseif statName == "armor" then
		return base.armor + 3.5 * (level - 1)
	elseif statName == "magicResist" then
		return base.magicResist + 1.25 * (level - 1)
	else
		return base[statName] or 0
	end
end

-- EXP needed to reach next level
function ChampionManager.expForLevel(level)
	return Constants.EXP_PER_LEVEL[level] or math.huge
end

-- Award EXP to a player; handles level-up
function ChampionManager.awardExp(player, amount)
	local gm = _G.GameManager
	if not gm then return end
	local pData = gm.getPlayerData(player)
	if not pData or pData.level >= Constants.MAX_LEVEL then return end

	pData.exp += amount
	while pData.level < Constants.MAX_LEVEL and pData.exp >= ChampionManager.expForLevel(pData.level) do
		pData.exp -= ChampionManager.expForLevel(pData.level)
		pData.level += 1
		Remotes.LevelUp:FireClient(player, pData.level)
		-- Heal on level up
		local model = workspace:FindFirstChild("Champion_" .. player.UserId)
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local maxHp = ChampionManager.getStat(pData.champion, "hp", pData.level)
				humanoid.MaxHealth = maxHp
				humanoid.Health = math.min(humanoid.Health + maxHp * 0.1, maxHp)
			end
		end
	end

	Remotes.UpdateHUD:FireClient(player, {exp = pData.exp, level = pData.level})
end

-- Apply damage with armor/MR mitigation
function ChampionManager.dealDamage(targetModel, amount, damageType, sourcePlayer)
	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local mitigation = 0
	local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
	if targetPlayer then
		local gm = _G.GameManager
		local pData = gm and gm.getPlayerData(targetPlayer)
		if pData then
			if damageType == "physical" then
				local armor = ChampionManager.getStat(pData.champion, "armor", pData.level)
				mitigation = armor / (armor + 100)
			elseif damageType == "magic" then
				local mr = ChampionManager.getStat(pData.champion, "magicResist", pData.level)
				mitigation = mr / (mr + 100)
			end
		end
	end

	local finalDamage = amount * (1 - mitigation)
	humanoid:TakeDamage(finalDamage)

	if humanoid.Health <= 0 and sourcePlayer then
		_G.GameManager.recordKill(sourcePlayer, targetPlayer)
		_G.GameManager.addGold(sourcePlayer, Constants.KILL_GOLD)
		ChampionManager.awardExp(sourcePlayer, 300)
	end
end

return ChampionManager
