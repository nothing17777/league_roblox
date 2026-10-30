-- Creates and returns all RemoteEvents / RemoteFunctions used across client-server boundary

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getOrCreate(parent, class, name)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	local obj = Instance.new(class)
	obj.Name = name
	obj.Parent = parent
	return obj
end

local folder = getOrCreate(ReplicatedStorage, "Folder", "Remotes")

-- Champion selection
Remotes.SelectChampion     = getOrCreate(folder, "RemoteEvent", "SelectChampion")
Remotes.ChampionSelected   = getOrCreate(folder, "RemoteEvent", "ChampionSelected")

-- Gameplay
Remotes.CastAbility        = getOrCreate(folder, "RemoteEvent", "CastAbility")
Remotes.UseItem            = getOrCreate(folder, "RemoteEvent", "UseItem")
Remotes.BuyItem            = getOrCreate(folder, "RemoteEvent", "BuyItem")
Remotes.SellItem           = getOrCreate(folder, "RemoteEvent", "SellItem")
Remotes.MoveOrder          = getOrCreate(folder, "RemoteEvent", "MoveOrder")
Remotes.AttackOrder        = getOrCreate(folder, "RemoteEvent", "AttackOrder")
Remotes.RecallStart        = getOrCreate(folder, "RemoteEvent", "RecallStart")
Remotes.RecallCancel       = getOrCreate(folder, "RemoteEvent", "RecallCancel")

-- State sync (server → client)
Remotes.UpdateHUD          = getOrCreate(folder, "RemoteEvent", "UpdateHUD")
Remotes.ChampionDied       = getOrCreate(folder, "RemoteEvent", "ChampionDied")
Remotes.ChampionRespawned  = getOrCreate(folder, "RemoteEvent", "ChampionRespawned")
Remotes.TowerDestroyed     = getOrCreate(folder, "RemoteEvent", "TowerDestroyed")
Remotes.InhibitorDestroyed = getOrCreate(folder, "RemoteEvent", "InhibitorDestroyed")
Remotes.NexusDestroyed     = getOrCreate(folder, "RemoteEvent", "NexusDestroyed")
Remotes.GoldUpdated        = getOrCreate(folder, "RemoteEvent", "GoldUpdated")
Remotes.LevelUp            = getOrCreate(folder, "RemoteEvent", "LevelUp")
Remotes.KillFeed           = getOrCreate(folder, "RemoteEvent", "KillFeed")

-- Functions
Remotes.GetGameState       = getOrCreate(folder, "RemoteFunction", "GetGameState")
Remotes.GetShopItems       = getOrCreate(folder, "RemoteFunction", "GetShopItems")

return Remotes
