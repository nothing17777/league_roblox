# League of Legends — Roblox Remake

A faithful League of Legends remake built in Roblox using Luau.  
Assets are extracted from the real LoL client (patch 16.21).

---

## Quick Start (for coding agents)

### Setup
1. Install [Rojo](https://rojo.space/) (`aftman add rojo-rbx/rojo`)
2. Run `rojo serve` in this folder
3. Open Roblox Studio → connect Rojo plugin
4. All scripts sync automatically into the correct services

### Repo Structure

```
league_roblox/
├── default.project.json          ← Rojo config (maps src/ → Roblox services)
├── src/
│   ├── server/                   → ServerScriptService
│   │   ├── GameManager.server.lua    main game loop, phases, teams
│   │   ├── ChampionManager.lua       stats, leveling, damage calc
│   │   ├── MinionManager.lua         wave spawning, pathfinding, gold
│   │   ├── TowerManager.lua          aggro, attack, destruction
│   │   ├── SpawnManager.lua          champion model creation, respawn
│   │   └── ShopManager.lua           item buying/selling
│   ├── client/                   → StarterPlayerScripts
│   │   ├── HUD.client.lua            health/mana bars, gold, kill feed
│   │   ├── AbilityInput.client.lua   Q/W/E/R/D/F + right-click move
│   │   ├── ShopUI.client.lua         P-key shop (grid of items)
│   │   └── ChampionSelect.client.lua champion picker with search
│   └── shared/                   → ReplicatedStorage
│       ├── ChampionData.lua          ALL 254 champions: base stats, roles, icons
│       ├── ItemData.lua              230 shop items: price, stats, build paths
│       ├── Constants.lua             map size, gold values, spawn timers
│       └── Remotes.lua               all RemoteEvents / RemoteFunctions
├── assets/
│   ├── champion_icons/           255 PNGs named {id}.png  (e.g. 1.png = Annie)
│   └── item_icons/               609 PNGs named by item (e.g. 1001_boots_of_speed.png)
└── docs/
    └── SYSTEMS.md                deeper notes on each system
```

---

## Champion Data

`src/shared/ChampionData.lua` contains all 254 champions with:

| Field | Description |
|---|---|
| `id` | Riot's champion ID (matches icon filename: `{id}.png`) |
| `name` | Display name ("Miss Fortune") |
| `title` | Tagline ("the Bounty Hunter") |
| `roles` | Array: `"fighter"`, `"mage"`, `"marksman"`, `"assassin"`, `"tank"`, `"support"` |
| `hp / hpPerLvl` | Base HP at level 1 and growth per level |
| `ad / adPerLvl` | Base attack damage and growth |
| `attackSpeed` | Base attacks per second |
| `armor / magicResist` | Base resistances |
| `moveSpeed` | Base movement speed (LoL units; divide by ~40 for Roblox WalkSpeed) |
| `attackRange` | Attack range in LoL units (≤300 = melee) |
| `mp / manaType` | Base mana and resource type (`"mana"`, `"energy"`, `"none"`, `"fury"`, etc.) |

### Stat scaling formula
```
stat_at_level = base_stat + (growth_per_level × (level - 1))
-- For armor/MR: armor + 3.5*(level-1), mr + 1.25*(level-1)
-- Damage reduction: armor / (armor + 100)
```

---

## Item Data

`src/shared/ItemData.lua` — 230 items with:
- `price` / `totalPrice` (component cost vs. full build cost)
- `buildsFrom` / `buildsInto` (item ID arrays for recipe tree)
- `stats` — parsed from client HTML: `ad`, `ap`, `hp`, `armor`, `mr`, `as`, `crit`, `ms`, `mana`, `lifesteal`, `haste`
- `icon` — path to `assets/item_icons/{filename}.png`

---

## Assets

### Champion Icons (`assets/champion_icons/`)
- 255 PNG files named `{championId}.png`
- Mapped via `xxhash64` from Riot's WAD files using the LCU hash table
- Upload to Roblox as Image assets; reference by champion ID from `ChampionData`

### Item Icons (`assets/item_icons/`)
- 609 PNG files with human-readable names (e.g. `3031_infinity_edge.png`)
- Paths match `ItemData.items[id].icon`

---

## What to Build Next

### Priority 1 — Core Gameplay
- [ ] **Ability system** — 4 abilities per champion with cooldowns, projectile/AoE hitboxes
  - Start with 5 simple champions (Garen, Ashe, Annie, Malphite, Nasus)
  - Each ability is a ModuleScript in `src/shared/Abilities/{ChampionAlias}/`
- [ ] **Auto-attack system** — right-click to attack, attack speed animation, on-hit effects
- [ ] **Minimap** — top-down camera thumbnail, player/minion dots

### Priority 2 — Map
- [ ] **Summoner's Rift model** — build SR lanes, jungle camps, river in Roblox Studio
  - Update waypoints in `MinionManager.lua` and spawn points in `SpawnManager.lua`
- [ ] **Jungle camps** — Dragon, Baron, Buffs (Blue/Red Sentinel)
- [ ] **Inhibitors** — destroyable, respawn after 5 min, empower minion waves

### Priority 3 — Polish
- [ ] **Minimap** — viewport frame with overhead camera
- [ ] **Item active effects** — Flash (D/F key), Ignite, Teleport summoner spells
- [ ] **Runes** — simple Keystone effects (e.g. Conqueror, Electrocute)
- [ ] **Death screen** — countdown timer, respawn button
- [ ] **Scoreboard** (Tab key) — KDA, gold, items for all players

---

## Architecture Notes

- **`_G.GameManager`** — global singleton exposed so all server modules can call `addGold`, `getPlayerData`, `recordKill`, `checkWin` without circular requires
- **Damage formula** — physical: `raw × (1 - armor/(armor+100))`, magic: `raw × (1 - mr/(mr+100))`, true: no reduction
- **Minion wave timing** — first wave at 1:05 (65s), every 30s thereafter; every 3rd wave is a siege wave
- **Tower aggro** — prioritizes targets attacking the tower, falls back to closest enemy in 775-unit range
- **Respawn timer** — `6 + level × 2.5` seconds (simplified; real LoL uses a more complex formula)

---

## Source

Assets extracted from League of Legends client patch 16.21 using [cdtb](https://github.com/CommunityDragon/CDTB).  
Champion stats sourced from Riot's LCU game-data endpoint.  
This project is a fan-made educational remake. League of Legends is © Riot Games.
