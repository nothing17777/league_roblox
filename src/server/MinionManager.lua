-- Spawns and controls minion waves for both teams

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

local MinionManager = {}

-- Lane waypoints: Blue side → Red side (mirror for Red)
-- These are placeholder positions — update to match your actual map geometry
local BLUE_WAYPOINTS = {
	-- Top lane
	top = {
		Vector3.new(-580, 0, -600),
		Vector3.new(-580, 0, 0),
		Vector3.new(-580, 0, 580),
		Vector3.new(600, 0, 580),
	},
	-- Mid lane
	mid = {
		Vector3.new(-580, 0, -580),
		Vector3.new(0, 0, 0),
		Vector3.new(580, 0, 580),
	},
	-- Bot lane
	bot = {
		Vector3.new(-600, 0, -580),
		Vector3.new(0, 0, -580),
		Vector3.new(580, 0, -580),
		Vector3.new(580, 0, 600),
	},
}

local waveCount = 0
local activeMinions = {}
local spawning = false

local function buildMinionModel(team, minionType, position)
	local model = Instance.new("Model")
	model.Name = "Minion_" .. team .. "_" .. minionType .. "_" .. math.random(1e6)

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(1.5, 1.5, 1.5)
	hrp.CFrame = CFrame.new(position)
	hrp.BrickColor = (team == Constants.TEAM_BLUE) and BrickColor.new("Bright blue") or BrickColor.new("Bright red")
	hrp.Parent = model

	local humanoid = Instance.new("Humanoid")
	local hp = minionType == "siege" and Constants.MINION_SIEGE_HP
		or minionType == "melee" and Constants.MINION_MELEE_HP
		or Constants.MINION_RANGED_HP
	humanoid.MaxHealth = hp
	humanoid.Health = hp
	humanoid.WalkSpeed = minionType == "siege" and 8 or 12
	humanoid.Parent = model

	local teamTag = Instance.new("StringValue")
	teamTag.Name = "Team"
	teamTag.Value = team
	teamTag.Parent = model

	local typeTag = Instance.new("StringValue")
	typeTag.Name = "MinionType"
	typeTag.Value = minionType
	typeTag.Parent = model

	model.PrimaryPart = hrp
	model.Parent = workspace
	return model
end

local function getWaypoints(team, lane)
	if team == Constants.TEAM_BLUE then
		return BLUE_WAYPOINTS[lane]
	else
		-- Mirror: reverse waypoints for red team
		local wp = {}
		for i = #BLUE_WAYPOINTS[lane], 1, -1 do
			wp[#wp + 1] = BLUE_WAYPOINTS[lane][i]
		end
		return wp
	end
end

local function moveMinion(model, waypoints)
	task.spawn(function()
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		for _, wp in ipairs(waypoints) do
			if not model.Parent then return end
			humanoid:MoveTo(wp)
			humanoid.MoveToFinished:Wait()
		end
		-- Reached enemy base — destroy (no nexus interaction yet)
		if model.Parent then model:Destroy() end
	end)
end

local function spawnWave(team, lane, isSiege)
	local waypoints = getWaypoints(team, lane)
	if not waypoints or #waypoints == 0 then return end

	local spawnPos = waypoints[1]
	local types = isSiege
		and {"melee","melee","melee","ranged","ranged","ranged","siege"}
		or  {"melee","melee","melee","ranged","ranged","ranged"}

	for i, mType in ipairs(types) do
		local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
		local model = buildMinionModel(team, mType, spawnPos + offset)
		table.insert(activeMinions, model)

		-- Wire death → gold
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		humanoid.Died:Connect(function()
			local gm = _G.GameManager
			if gm then
				local goldAmt = mType == "siege" and Constants.MINION_SIEGE_GOLD
					or mType == "melee" and Constants.MINION_MELEE_GOLD
					or Constants.MINION_RANGED_GOLD
				-- Award gold to nearest enemy player (simplified: award all enemies)
				local minionTeam = model:FindFirstChild("Team") and model.Team.Value
				for _, player in ipairs(game.Players:GetPlayers()) do
					local pData = gm.getPlayerData(player)
					if pData and pData.team ~= minionTeam then
						gm.addGold(player, goldAmt)
					end
				end
			end
			-- Remove from tracking
			for j, m in ipairs(activeMinions) do
				if m == model then table.remove(activeMinions, j) break end
			end
		end)

		moveMinion(model, waypoints)
		task.wait(0.5)
	end
end

function MinionManager.startWaves()
	spawning = true
	task.spawn(function()
		while spawning do
			waveCount += 1
			local isSiege = waveCount % 3 == 0
			for _, team in ipairs({Constants.TEAM_BLUE, Constants.TEAM_RED}) do
				for _, lane in ipairs({"top", "mid", "bot"}) do
					spawnWave(team, lane, isSiege)
					task.wait(0.2)
				end
			end
			task.wait(Constants.MINION_WAVE_INTERVAL)
		end
	end)
end

function MinionManager.tick(_elapsed)
	-- Future: scale minion stats by elapsed time
end

function MinionManager.stop()
	spawning = false
	for _, m in ipairs(activeMinions) do
		if m and m.Parent then m:Destroy() end
	end
	activeMinions = {}
end

return MinionManager
