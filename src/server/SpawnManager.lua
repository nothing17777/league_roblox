-- Places champion models in world; handles respawning

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local ChampionData = require(Shared.ChampionData)
local ChampionManager = require(script.Parent.ChampionManager)
local Remotes = require(Shared.Remotes)

local SpawnManager = {}

-- Spawn points (set these to match your map's actual positions)
local SPAWN_POINTS = {
	[Constants.TEAM_BLUE] = Vector3.new(-600, 5, -600),
	[Constants.TEAM_RED]  = Vector3.new(600, 5, 600),
}

local function buildChampionModel(player, alias, team)
	local stats = ChampionData.stats[alias]
	if not stats then return nil end

	local model = Instance.new("Model")
	model.Name = "Champion_" .. player.UserId

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Anchored = false
	hrp.CFrame = CFrame.new(SPAWN_POINTS[team] or Vector3.new(0, 5, 0))
	hrp.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = ChampionManager.getStat(alias, "hp", 1)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = math.floor(stats.moveSpeed / 40) -- convert LoL MS to Roblox WalkSpeed
	humanoid.Parent = model

	-- Team color tag
	local tag = Instance.new("StringValue")
	tag.Name = "Team"
	tag.Value = team
	tag.Parent = model

	local champTag = Instance.new("StringValue")
	champTag.Name = "Champion"
	champTag.Value = alias
	champTag.Parent = model

	local ownerTag = Instance.new("NumberValue")
	ownerTag.Name = "OwnerId"
	ownerTag.Value = player.UserId
	ownerTag.Parent = model

	model.PrimaryPart = hrp
	model.Parent = workspace
	return model
end

function SpawnManager.spawnChampion(player, alias, team)
	-- Remove old model if any
	local old = workspace:FindFirstChild("Champion_" .. player.UserId)
	if old then old:Destroy() end

	local model = buildChampionModel(player, alias, team)
	if not model then
		warn("Could not build model for " .. alias)
		return
	end

	-- Wire humanoid death → respawn
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.Died:Connect(function()
		Remotes.ChampionDied:FireAllClients(player, alias)
		local pData = _G.GameManager and _G.GameManager.getPlayerData(player)
		local level = pData and pData.level or 1
		local respawnTime = Constants.RESPAWN_BASE + level * 2.5
		task.delay(respawnTime, function()
			if Players:FindFirstChild(player.Name) then
				SpawnManager.spawnChampion(player, alias, team)
				Remotes.ChampionRespawned:FireAllClients(player, alias)
			end
		end)
	end)

	print(player.Name .. " spawned as " .. alias .. " for team " .. team)
end

return SpawnManager
