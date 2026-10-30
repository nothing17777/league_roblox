-- Game-wide constants matching real League of Legends values

local Constants = {}

-- Map
Constants.MAP_SIZE = Vector3.new(1400, 0, 1400) -- Summoner's Rift scale (studs)
Constants.MAP_ID = "Map11" -- Summoner's Rift

-- Teams
Constants.TEAM_BLUE = "Blue"
Constants.TEAM_RED = "Red"

-- Game timing
Constants.MINION_SPAWN_DELAY = 65  -- seconds after game start
Constants.MINION_WAVE_INTERVAL = 30
Constants.DRAGON_SPAWN_TIME = 300
Constants.BARON_SPAWN_TIME = 1200
Constants.RESPAWN_BASE = 6  -- base seconds; scales with level

-- Structures
Constants.TOWER_AGGRO_RANGE = 775
Constants.INHIBITOR_RESPAWN_TIME = 300
Constants.NEXUS_HP = 5000

-- Minion stats
Constants.MINION_MELEE_HP = 484
Constants.MINION_MELEE_AD = 21
Constants.MINION_MELEE_ARMOR = 0
Constants.MINION_RANGED_HP = 290
Constants.MINION_RANGED_AD = 23
Constants.MINION_SIEGE_HP = 1300
Constants.MINION_SIEGE_AD = 70

-- Gold
Constants.KILL_GOLD = 300
Constants.ASSIST_GOLD = 150
Constants.MINION_MELEE_GOLD = 21
Constants.MINION_RANGED_GOLD = 14
Constants.MINION_SIEGE_GOLD = 60
Constants.TOWER_GOLD = 150
Constants.TOWER_KILL_BONUS = 100
Constants.INHIBITOR_GOLD = 50

-- Levels
Constants.MAX_LEVEL = 18
Constants.EXP_PER_LEVEL = {
	0, 280, 380, 480, 580, 680, 780, 880, 1000,
	1120, 1240, 1360, 1480, 1600, 1720, 1840, 1960, 2080
}

-- Runes (keystones)
Constants.KEYSTONE_IDS = {8005, 8008, 8021, 8010, 9101, 9111, 8214, 8229, 8230, 8437, 8439, 8465, 8351, 8358, 8369}

return Constants
