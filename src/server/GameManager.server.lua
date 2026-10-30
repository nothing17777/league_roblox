-- Central game loop: manages game phases, timers, and coordinates all sub-systems

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local Remotes = require(Shared.Remotes)
local ChampionData = require(Shared.ChampionData)

local MinionManager = require(script.Parent.MinionManager)
local TowerManager  = require(script.Parent.TowerManager)
local SpawnManager  = require(script.Parent.SpawnManager)
local ShopManager   = require(script.Parent.ShopManager)

-- Game state
local GameState = {
	phase = "lobby",   -- lobby | champion_select | in_game | ended
	startTime = 0,
	winner = nil,
	players = {},      -- [player] = { team, champion, stats }
}

local function getElapsed()
	return os.clock() - GameState.startTime
end

-- Assign players to teams on join
Players.PlayerAdded:Connect(function(player)
	local blueCount, redCount = 0, 0
	for _, data in pairs(GameState.players) do
		if data.team == Constants.TEAM_BLUE then blueCount += 1
		else redCount += 1 end
	end
	local team = (blueCount <= redCount) and Constants.TEAM_BLUE or Constants.TEAM_RED
	GameState.players[player] = {
		team = team,
		champion = nil,
		level = 1,
		exp = 0,
		gold = 500,
		items = {},
		kills = 0,
		deaths = 0,
		assists = 0,
	}
	print(player.Name .. " joined team " .. team)
end)

Players.PlayerRemoving:Connect(function(player)
	GameState.players[player] = nil
end)

-- Champion select
Remotes.SelectChampion.OnServerEvent:Connect(function(player, alias)
	local pData = GameState.players[player]
	if not pData then return end
	if not ChampionData.stats[alias] then
		warn("Unknown champion: " .. tostring(alias))
		return
	end
	pData.champion = alias
	Remotes.ChampionSelected:FireAllClients(player, alias, pData.team)
	SpawnManager.spawnChampion(player, alias, pData.team)
end)

-- Shop
Remotes.GetShopItems.OnServerInvoke = function(player)
	return ShopManager.getAvailableItems(GameState.players[player])
end

Remotes.BuyItem.OnServerEvent:Connect(function(player, itemId)
	ShopManager.buyItem(player, GameState.players[player], itemId)
end)

Remotes.SellItem.OnServerEvent:Connect(function(player, itemId)
	ShopManager.sellItem(player, GameState.players[player], itemId)
end)

-- GetGameState
Remotes.GetGameState.OnServerInvoke = function(_player)
	return {
		phase = GameState.phase,
		elapsed = getElapsed(),
	}
end

-- Main game loop
local function startGame()
	GameState.phase = "in_game"
	GameState.startTime = os.clock()
	print("Game started!")

	-- Delayed minion spawn
	task.delay(Constants.MINION_SPAWN_DELAY, function()
		MinionManager.startWaves()
	end)

	-- Tower setup
	TowerManager.initialize()

	-- Game timer loop
	task.spawn(function()
		while GameState.phase == "in_game" do
			local elapsed = getElapsed()
			MinionManager.tick(elapsed)
			task.wait(0.5)
		end
	end)
end

-- Win condition check
local function checkWinCondition(team)
	GameState.phase = "ended"
	GameState.winner = team
	Remotes.NexusDestroyed:FireAllClients(team)
	print("Game over! Winner: " .. team)
end

-- Expose for other managers
_G.GameManager = {
	getState = function() return GameState end,
	getPlayerData = function(player) return GameState.players[player] end,
	addGold = function(player, amount)
		local pData = GameState.players[player]
		if not pData then return end
		pData.gold += amount
		Remotes.GoldUpdated:FireClient(player, pData.gold)
	end,
	recordKill = function(killer, victim)
		local kData = GameState.players[killer]
		local vData = GameState.players[victim]
		if kData then kData.kills += 1 end
		if vData then vData.deaths += 1 end
		Remotes.KillFeed:FireAllClients(killer and killer.Name or "Minion", victim and victim.Name or "?")
	end,
	checkWin = checkWinCondition,
}

-- Auto-start when enough players (can be adjusted)
task.wait(5)
if #Players:GetPlayers() >= 2 then
	startGame()
else
	Players.PlayerAdded:Wait()
	task.wait(2)
	startGame()
end
