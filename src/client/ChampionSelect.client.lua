-- Champion select screen: shown before game starts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ChampionData = require(Shared.ChampionData)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChampionSelect"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
bg.Parent = screenGui

local title = Instance.new("TextLabel")
title.Text = "SELECT YOUR CHAMPION"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(200, 170, 50)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Size = UDim2.new(0.6, 0, 0.08, 0)
title.Position = UDim2.new(0.2, 0, 0.02, 0)
title.Parent = bg

-- Search bar
local searchBox = Instance.new("TextBox")
searchBox.PlaceholderText = "Search champion..."
searchBox.Font = Enum.Font.Gotham
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
searchBox.Size = UDim2.new(0.3, 0, 0.04, 0)
searchBox.Position = UDim2.new(0.35, 0, 0.11, 0)
searchBox.Parent = bg

-- Grid
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.7, 0, 0.75, 0)
scroll.Position = UDim2.new(0.15, 0, 0.17, 0)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.Parent = bg

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 80, 0, 100)
grid.CellPadding = UDim2.new(0, 6, 0, 6)
grid.Parent = scroll

-- Details panel
local detailPanel = Instance.new("Frame")
detailPanel.Size = UDim2.new(0.22, 0, 0.75, 0)
detailPanel.Position = UDim2.new(0.77, 0, 0.17, 0)
detailPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
detailPanel.Visible = false
detailPanel.Parent = bg

local detailName = Instance.new("TextLabel")
detailName.Font = Enum.Font.GothamBold
detailName.TextColor3 = Color3.fromRGB(255, 255, 255)
detailName.BackgroundTransparency = 1
detailName.TextScaled = true
detailName.Size = UDim2.new(1, 0, 0.08, 0)
detailName.Position = UDim2.new(0, 0, 0.02, 0)
detailName.Parent = detailPanel

local detailStats = Instance.new("TextLabel")
detailStats.Font = Enum.Font.Gotham
detailStats.TextColor3 = Color3.fromRGB(200, 200, 200)
detailStats.BackgroundTransparency = 1
detailStats.TextScaled = false
detailStats.TextSize = 12
detailStats.TextWrapped = true
detailStats.Size = UDim2.new(1, -10, 0.6, 0)
detailStats.Position = UDim2.new(0, 5, 0.12, 0)
detailStats.TextXAlignment = Enum.TextXAlignment.Left
detailStats.TextYAlignment = Enum.TextYAlignment.Top
detailStats.Parent = detailPanel

local confirmBtn = Instance.new("TextButton")
confirmBtn.Text = "SELECT"
confirmBtn.Font = Enum.Font.GothamBold
confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
confirmBtn.Size = UDim2.new(0.8, 0, 0.1, 0)
confirmBtn.Position = UDim2.new(0.1, 0, 0.88, 0)
confirmBtn.Parent = detailPanel

local selectedAlias = nil

local function showDetail(alias)
	local s = ChampionData.stats[alias]
	if not s then return end
	selectedAlias = alias
	detailName.Text = s.name .. "\n" .. s.title
	detailStats.Text = string.format(
		"HP: %d (+%g/lvl)\nAD: %g (+%g/lvl)\nArmor: %d\nMR: %d\nMove Speed: %d\nRange: %d\nMana: %d (%s)\nRoles: %s",
		s.hp, s.hpPerLvl,
		s.ad, s.adPerLvl,
		s.armor, s.magicResist, s.moveSpeed, s.attackRange,
		s.mp, s.manaType,
		table.concat(s.roles, ", ")
	)
	detailPanel.Visible = true
end

-- Sort champions alphabetically
local sortedChamps = {}
for alias, _ in pairs(ChampionData.stats) do
	table.insert(sortedChamps, alias)
end
table.sort(sortedChamps)

local cards = {}
for _, alias in ipairs(sortedChamps) do
	local s = ChampionData.stats[alias]

	local card = Instance.new("TextButton")
	card.Name = alias
	card.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
	card.BorderSizePixel = 0
	card.Text = ""
	card.Parent = scroll
	cards[alias] = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = s.name
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.7, 0)
	nameLabel.Parent = card

	card.MouseButton1Click:Connect(function()
		showDetail(alias)
	end)
end

scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 10)

-- Search filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = searchBox.Text:lower()
	for alias, card in pairs(cards) do
		card.Visible = query == "" or alias:lower():find(query, 1, true) ~= nil
	end
end)

-- Confirm selection
confirmBtn.MouseButton1Click:Connect(function()
	if selectedAlias then
		Remotes.SelectChampion:FireServer(selectedAlias)
		screenGui:Destroy()
	end
end)
