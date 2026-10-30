# System Design Notes

## Damage Model
Physical: `dmg * armor/(armor+100)` reduction
Magic: `dmg * mr/(mr+100)` reduction  
True damage: no reduction

## Movement Speed Conversion
LoL MS 325 ≈ Roblox WalkSpeed 8  
Formula: `walkSpeed = math.floor(lolMS / 40)`

## Champion Abilities (to implement)
Each champion needs a ModuleScript at `src/shared/Abilities/{Alias}.lua`:
```lua
return {
    Q = { name = "", cd = 10, mp = 60, cast = function(caster, target) end },
    W = { ... },
    E = { ... },
    R = { name = "", cd = 120, mp = 100, cast = function(caster, target) end },
}
```

## Map Coordinate System
Roblox studs approximate LoL units at 1:1 scale for gameplay feel.
Map center = Vector3.new(0, 0, 0)
Blue base = (-600, y, -600), Red base = (600, y, 600)

## Gold Income Sources
| Source | Gold |
|--------|------|
| Melee minion | 21 |
| Ranged minion | 14 |
| Siege minion | 60 |
| Champion kill | 300 |
| Assist | 150 |
| Tower | 150 (+100 bonus to killer) |
| Inhibitor | 50 |

## Minion Wave Composition
- Normal wave: 3 melee + 3 ranged
- Siege wave (every 3rd): 3 melee + 3 ranged + 1 super minion
- After inhibitor falls: waves include 1 super minion per destroyed inhibitor
