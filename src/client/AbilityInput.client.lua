-- Handles Q/W/E/R/D/F ability and summoner spell key inputs

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

-- Key → ability slot mapping
local ABILITY_KEYS = {
	[Enum.KeyCode.Q] = "Q",
	[Enum.KeyCode.W] = "W",
	[Enum.KeyCode.E] = "E",
	[Enum.KeyCode.R] = "R",
	[Enum.KeyCode.D] = "D",  -- Summoner spell 1
	[Enum.KeyCode.F] = "F",  -- Summoner spell 2
}

local cooldowns = {}  -- key → endTime

local function isOnCooldown(slot)
	return cooldowns[slot] and os.clock() < cooldowns[slot]
end

local function getCursorWorldPos()
	local camera = workspace.CurrentCamera
	local mouse = player:GetMouse()
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character or Instance.new("Part")}
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
	if result then
		return result.Position
	end
	return unitRay.Origin + unitRay.Direction * 300
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local slot = ABILITY_KEYS[input.KeyCode]
	if not slot then return end
	if isOnCooldown(slot) then return end

	local targetPos = getCursorWorldPos()
	Remotes.CastAbility:FireServer(slot, targetPos)
	-- Optimistic cooldown placeholder (server will send real value)
	cooldowns[slot] = os.clock() + 1
end)

-- Right-click to move
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local targetPos = getCursorWorldPos()
		-- Check if clicking on an enemy model
		local camera = workspace.CurrentCamera
		local mouse = player:GetMouse()
		local target = mouse.Target
		if target and target.Parent then
			local teamTag = target.Parent:FindFirstChild("Team")
			local myData = _G.myTeam
			if teamTag and myData and teamTag.Value ~= myData then
				Remotes.AttackOrder:FireServer(target.Parent)
				return
			end
		end
		Remotes.MoveOrder:FireServer(targetPos)
	end
end)

-- B key to recall
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		Remotes.RecallStart:FireServer()
	end
end)
