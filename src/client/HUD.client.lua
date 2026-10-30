-- Draws the in-game HUD: health bar, mana bar, ability icons, gold, minimap frame

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Build ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ── Health / Mana bars ──────────────────────────────────────────────────────
local function makeBar(parent, name, pos, size, color)
	local bg = Instance.new("Frame")
	bg.Name = name .. "BG"
	bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	bg.Position = pos
	bg.Size = size
	bg.Parent = parent

	local fill = Instance.new("Frame")
	fill.Name = name .. "Fill"
	fill.BackgroundColor3 = color
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Parent = bg

	return fill
end

local bottomPanel = Instance.new("Frame")
bottomPanel.Name = "BottomPanel"
bottomPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
bottomPanel.BackgroundTransparency = 0.3
bottomPanel.Size = UDim2.new(1, 0, 0.12, 0)
bottomPanel.Position = UDim2.new(0, 0, 0.88, 0)
bottomPanel.Parent = screenGui

local hpFill   = makeBar(bottomPanel, "HP",   UDim2.new(0.3, 5, 0.15, 0), UDim2.new(0.15, 0, 0.2, 0), Color3.fromRGB(0, 200, 80))
local manaFill = makeBar(bottomPanel, "Mana", UDim2.new(0.3, 5, 0.4, 0),  UDim2.new(0.15, 0, 0.1, 0), Color3.fromRGB(30, 100, 255))

-- ── Gold display ────────────────────────────────────────────────────────────
local goldLabel = Instance.new("TextLabel")
goldLabel.Name = "Gold"
goldLabel.Text = "500 G"
goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
goldLabel.BackgroundTransparency = 1
goldLabel.Font = Enum.Font.GothamBold
goldLabel.TextScaled = true
goldLabel.Size = UDim2.new(0.06, 0, 0.06, 0)
goldLabel.Position = UDim2.new(0.47, 0, 0.89, 0)
goldLabel.Parent = screenGui

-- ── Level display ───────────────────────────────────────────────────────────
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "Level"
levelLabel.Text = "1"
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextScaled = true
levelLabel.Size = UDim2.new(0.03, 0, 0.04, 0)
levelLabel.Position = UDim2.new(0.265, 0, 0.915, 0)
levelLabel.Parent = screenGui

-- ── Ability slots (Q W E R) ─────────────────────────────────────────────────
local abilityKeys = {"Q", "W", "E", "R"}
local abilitySlots = {}

for i, key in ipairs(abilityKeys) do
	local slot = Instance.new("Frame")
	slot.Name = "Ability_" .. key
	slot.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	slot.Size = UDim2.new(0.05, 0, 0.09, 0)
	slot.Position = UDim2.new(0.38 + (i - 1) * 0.055, 0, 0.88, 0)
	slot.Parent = screenGui

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Text = key
	keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Size = UDim2.new(1, 0, 0.3, 0)
	keyLabel.Position = UDim2.new(0, 0, 0.7, 0)
	keyLabel.Font = Enum.Font.Gotham
	keyLabel.TextScaled = true
	keyLabel.Parent = slot

	abilitySlots[key] = slot
end

-- ── Kill feed (top right) ────────────────────────────────────────────────────
local killFeedFrame = Instance.new("Frame")
killFeedFrame.Name = "KillFeed"
killFeedFrame.BackgroundTransparency = 1
killFeedFrame.Size = UDim2.new(0.2, 0, 0.25, 0)
killFeedFrame.Position = UDim2.new(0.8, 0, 0, 0)
killFeedFrame.Parent = screenGui

local killFeedLayout = Instance.new("UIListLayout")
killFeedLayout.SortOrder = Enum.SortOrder.LayoutOrder
killFeedLayout.VerticalAlignment = Enum.VerticalAlignment.Top
killFeedLayout.Parent = killFeedFrame

local function addKillFeedEntry(killerName, victimName)
	local entry = Instance.new("TextLabel")
	entry.Text = killerName .. " ⚔ " .. victimName
	entry.TextColor3 = Color3.fromRGB(255, 255, 255)
	entry.BackgroundTransparency = 0.4
	entry.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	entry.Font = Enum.Font.Gotham
	entry.TextScaled = true
	entry.Size = UDim2.new(1, 0, 0, 24)
	entry.LayoutOrder = -os.clock()
	entry.Parent = killFeedFrame
	game:GetService("Debris"):AddItem(entry, 5)
end

-- ── Event handlers ───────────────────────────────────────────────────────────
Remotes.UpdateHUD.OnClientEvent:Connect(function(data)
	if data.gold    then goldLabel.Text  = data.gold .. " G" end
	if data.level   then levelLabel.Text = tostring(data.level) end
	if data.message then
		-- brief toast
		local toast = Instance.new("TextLabel")
		toast.Text = data.message
		toast.TextColor3 = Color3.fromRGB(255, 200, 0)
		toast.BackgroundTransparency = 0.3
		toast.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		toast.Font = Enum.Font.GothamBold
		toast.TextScaled = true
		toast.Size = UDim2.new(0.3, 0, 0.05, 0)
		toast.Position = UDim2.new(0.35, 0, 0.75, 0)
		toast.Parent = screenGui
		game:GetService("Debris"):AddItem(toast, 2)
	end
end)

Remotes.GoldUpdated.OnClientEvent:Connect(function(gold)
	goldLabel.Text = tostring(gold) .. " G"
end)

Remotes.LevelUp.OnClientEvent:Connect(function(level)
	levelLabel.Text = tostring(level)
end)

Remotes.KillFeed.OnClientEvent:Connect(function(killer, victim)
	addKillFeedEntry(killer, victim)
end)

-- Health bar sync from character
local function syncBars()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local ratio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
	hpFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
end

game:GetService("RunService").RenderStepped:Connect(syncBars)
