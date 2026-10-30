-- Manages towers: aggro, attack, and destruction

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)
local Remotes = require(Shared.Remotes)

local TowerManager = {}

-- Tower positions (Summoner's Rift layout, placeholder studs)
-- Layout: outer, inner, inhibitor towers per lane + nexus towers
local TOWER_CONFIG = {
	[Constants.TEAM_BLUE] = {
		{ name = "TopOuter",       pos = Vector3.new(-450, 0, 100),  hp = 2250, lane = "top" },
		{ name = "TopInner",       pos = Vector3.new(-450, 0, 350),  hp = 2250, lane = "top" },
		{ name = "TopInhibitor",   pos = Vector3.new(-450, 0, 550),  hp = 1400, lane = "top" },
		{ name = "MidOuter",       pos = Vector3.new(-150, 0, 150),  hp = 2250, lane = "mid" },
		{ name = "MidInner",       pos = Vector3.new(-300, 0, 300),  hp = 2250, lane = "mid" },
		{ name = "MidInhibitor",   pos = Vector3.new(-450, 0, 450),  hp = 1400, lane = "mid" },
		{ name = "BotOuter",       pos = Vector3.new(100, 0, -450),  hp = 2250, lane = "bot" },
		{ name = "BotInner",       pos = Vector3.new(350, 0, -450),  hp = 2250, lane = "bot" },
		{ name = "BotInhibitor",   pos = Vector3.new(550, 0, -450),  hp = 1400, lane = "bot" },
		{ name = "NexusTower1",    pos = Vector3.new(-580, 0, 550),  hp = 2250, lane = "nexus" },
		{ name = "NexusTower2",    pos = Vector3.new(-550, 0, 580),  hp = 2250, lane = "nexus" },
	},
	[Constants.TEAM_RED] = {
		{ name = "TopOuter",       pos = Vector3.new(450, 0, -100),  hp = 2250, lane = "top" },
		{ name = "TopInner",       pos = Vector3.new(450, 0, -350),  hp = 2250, lane = "top" },
		{ name = "TopInhibitor",   pos = Vector3.new(450, 0, -550),  hp = 1400, lane = "top" },
		{ name = "MidOuter",       pos = Vector3.new(150, 0, -150),  hp = 2250, lane = "mid" },
		{ name = "MidInner",       pos = Vector3.new(300, 0, -300),  hp = 2250, lane = "mid" },
		{ name = "MidInhibitor",   pos = Vector3.new(450, 0, -450),  hp = 1400, lane = "mid" },
		{ name = "BotOuter",       pos = Vector3.new(-100, 0, 450),  hp = 2250, lane = "bot" },
		{ name = "BotInner",       pos = Vector3.new(-350, 0, 450),  hp = 2250, lane = "bot" },
		{ name = "BotInhibitor",   pos = Vector3.new(-550, 0, 450),  hp = 1400, lane = "bot" },
		{ name = "NexusTower1",    pos = Vector3.new(580, 0, -550),  hp = 2250, lane = "nexus" },
		{ name = "NexusTower2",    pos = Vector3.new(550, 0, -580),  hp = 2250, lane = "nexus" },
	},
}

local towers = {}  -- model → { team, config, attackTarget, attackCooldown }

local function buildTowerModel(team, cfg)
	local model = Instance.new("Model")
	model.Name = "Tower_" .. team .. "_" .. cfg.name

	local part = Instance.new("Part")
	part.Name = "HumanoidRootPart"
	part.Size = Vector3.new(4, 12, 4)
	part.Anchored = true
	part.CFrame = CFrame.new(cfg.pos + Vector3.new(0, 6, 0))
	part.BrickColor = (team == Constants.TEAM_BLUE) and BrickColor.new("Bright blue") or BrickColor.new("Bright red")
	part.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = cfg.hp
	humanoid.Health = cfg.hp
	humanoid.Parent = model

	local teamTag = Instance.new("StringValue")
	teamTag.Name = "Team"
	teamTag.Value = team
	teamTag.Parent = model

	model.PrimaryPart = part
	model.Parent = workspace
	return model
end

local function findAggroTarget(towerModel, team)
	-- Priority: enemy champions attacking this tower → any enemy minion → any enemy champion in range
	local aggroRange = Constants.TOWER_AGGRO_RANGE
	local closestDist = math.huge
	local target = nil

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") then
			local objTeam = obj:FindFirstChild("Team")
			if objTeam and objTeam.Value ~= team then
				local hrp = obj:FindFirstChild("HumanoidRootPart")
				local humanoid = obj:FindFirstChildOfClass("Humanoid")
				if hrp and humanoid and humanoid.Health > 0 then
					local dist = (towerModel.PrimaryPart.Position - hrp.Position).Magnitude
					if dist <= aggroRange and dist < closestDist then
						closestDist = dist
						target = obj
					end
				end
			end
		end
	end
	return target
end

function TowerManager.initialize()
	for team, cfgList in pairs(TOWER_CONFIG) do
		for _, cfg in ipairs(cfgList) do
			local model = buildTowerModel(team, cfg)
			towers[model] = {
				team = team,
				config = cfg,
				attackTarget = nil,
				cooldown = 0,
			}

			local humanoid = model:FindFirstChildOfClass("Humanoid")
			humanoid.Died:Connect(function()
				towers[model] = nil
				Remotes.TowerDestroyed:FireAllClients(team, cfg.name)
				_G.GameManager.addGold = _G.GameManager.addGold  -- ensure available
				for _, player in ipairs(game.Players:GetPlayers()) do
					local pData = _G.GameManager and _G.GameManager.getPlayerData(player)
					if pData and pData.team ~= team then
						_G.GameManager.addGold(player, Constants.TOWER_GOLD)
					end
				end
				model:Destroy()
			end)
		end
	end

	-- Attack loop
	RunService.Heartbeat:Connect(function(dt)
		for model, data in pairs(towers) do
			data.cooldown -= dt
			if data.cooldown <= 0 then
				local target = findAggroTarget(model, data.team)
				if target then
					local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
					if targetHumanoid then
						-- Tower deals flat 152 damage base (scales in real LoL but we simplify)
						targetHumanoid:TakeDamage(152)
						data.cooldown = 1.0  -- 1 attack per second
					end
				end
			end
		end
	end)
end

return TowerManager
