-- In-game shop UI (opens with P key or near fountain)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Build shop ScreenGui
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "Shop"
shopGui.ResetOnSpawn = false
shopGui.Enabled = false
shopGui.Parent = playerGui

local background = Instance.new("Frame")
background.Size = UDim2.new(0.6, 0, 0.7, 0)
background.Position = UDim2.new(0.2, 0, 0.15, 0)
background.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
background.BorderSizePixel = 0
background.Parent = shopGui

-- Title
local title = Instance.new("TextLabel")
title.Text = "SHOP"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(200, 170, 50)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Size = UDim2.new(1, 0, 0.07, 0)
title.Parent = background

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✕"
closeBtn.Size = UDim2.new(0.06, 0, 0.06, 0)
closeBtn.Position = UDim2.new(0.93, 0, 0.005, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.Parent = background

closeBtn.MouseButton1Click:Connect(function()
	shopGui.Enabled = false
end)

-- Scroll frame for items
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 0.9, 0)
scrollFrame.Position = UDim2.new(0, 5, 0.08, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = background

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 120, 0, 120)
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
gridLayout.Parent = scrollFrame

local function buildItemCard(itemInfo)
	local card = Instance.new("TextButton")
	card.Name = "Item_" .. itemInfo.id
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	card.BorderSizePixel = 0
	card.Text = ""
	card.Parent = scrollFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = itemInfo.name
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.55, 0)
	nameLabel.Parent = card

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Text = tostring(itemInfo.price) .. " G"
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextScaled = true
	priceLabel.Size = UDim2.new(1, 0, 0.2, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.8, 0)
	priceLabel.Parent = card

	card.MouseButton1Click:Connect(function()
		Remotes.BuyItem:FireServer(itemInfo.id)
	end)
end

local itemsLoaded = false

local function loadItems()
	if itemsLoaded then return end
	itemsLoaded = true
	local items = Remotes.GetShopItems:InvokeServer()
	if not items then return end
	-- Sort by price
	table.sort(items, function(a, b) return a.price < b.price end)
	for _, item in ipairs(items) do
		buildItemCard(item)
	end
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
end

-- Toggle shop with P
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		shopGui.Enabled = not shopGui.Enabled
		if shopGui.Enabled then loadItems() end
	end
end)
