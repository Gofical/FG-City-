# ZCity Optimized - Sandbox Edition

A lightweight, optimized fork of Z-City gamemode focused on **Garry's Mod Sandbox** compatibility.

## 🎯 Goals

- **90% size reduction** (34MB → ~3MB)
- **Sandbox native** - works as addon or gamemode
- **Performance first** - optimized networking, caching, lazy loading
- **Clean codebase** - removed bloat, game modes, unused systems
- **Modular design** - enable/disable systems via convars

## 📦 What's Included

### Core Systems
| System | Description | ConVar |
|--------|-------------|--------|
| **Organism** | Health, armor, bleeding, fractures, stamina, hunger/thirst, poison, radiation | `hg_organism_enable` |
| **Inventory** | Grid-based, weight-limited, quickslots, stacking | `hg_inventory_enable` |
| **Movement** | Prone, lean (Q/E), slide (Ctrl+Shift), vault, sprint, stamina drain | `hg_movement_enable` |
| **Equipment** | Clothing, armor, backpacks, tactical gear with bonemerge | - |
| **Weapons** | Realistic base: heat, dirt, jams, attachments, fire modes | `hg_weapon_*` |

### Weapons (Examples)
- **Glock 17** - Pistol with optic/muzzle/tactical slots
- **M4A1** - Rifle with full attachment support (optic, muzzle, grip, tactical)
- **Attachment system** - Red dots, suppressors, grips, lasers, flashlights

### UI
- **Inventory Menu** (TAB) - Drag & drop, quickslots, equipment panel
- **HUD** - Health/armor/stamina, ammo, compass, status effects, crosshair
- **Hitmarkers** - Damage numbers, headshot indication

## 🚀 Installation

### As Gamemode
```
garrysmod/gamemodes/zcity_optimized/
```

### As Sandbox Addon (Recommended)
```
garrysmod/addons/zcity_optimized/
```
Just drop in addons folder - auto-loads via autorun.

## ⚙️ Configuration

All settings via convars (server-side, replicated):

```lua
// Organism
hg_organism_enable 1
hg_organism_health 100
hg_organism_regen_rate 0.5
hg_organism_bleed_chance 0.3
hg_organism_fracture_chance 0.1

// Damage
hg_damage_realistic 1
hg_damage_head_mult 2.5
hg_damage_limb_mult 0.7
hg_damage_armor_absorption 0.8

// Movement
hg_movement_enable 1
hg_movement_sprint_mult 1.5
hg_movement_crouch_mult 0.4
hg_movement_prone_mult 0.15
hg_movement_stamina_drain 8

// Inventory
hg_inventory_enable 1
hg_inventory_max_weight 50
hg_inventory_slots 24
hg_inventory_quick_slots 6

// Weapons
hg_weapon_jam_enable 1
hg_weapon_jam_chance 0.001
hg_weapon_overheat_enable 1
hg_weapon_dirt_enable 1

// Visuals
hg_visual_potatopc 0
hg_visual_blood_enable 1
hg_visual_ragdoll_enable 1

// Performance
hg_perf_max_ragdolls 20
hg_perf_max_shells 100
hg_perf_max_decals 500
hg_perf_cleanup_interval 30
```

## 🎮 Controls

| Key | Action |
|-----|--------|
| **TAB** | Open Inventory |
| **Shift** | Sprint |
| **Ctrl + Shift** (while sprinting) | Slide |
| **Ctrl + Walk** (standing still) | Prone |
| **Right Click** | Aim Down Sights |
| **Q / E** (while walking) | Lean Left/Right |
| **R** | Reload |
| **F** (while aiming) | Inspect Weapon |
| **R** (jammed) | Clear Jam |

## 📊 Performance Optimizations

- **Network compression** - Custom net library with type packing
- **Delta sync** - Only send changed organism/inventory data
- **Batched messages** - Combine multiple net messages per tick
- **Lazy loading** - Materials/models loaded on demand
- **Bone caching** - LookupBone results cached
- **Effect queue** - Client effects batched per frame
- **ConVar caching** - GetConVar results cached
- **No round system** - Removed all gamemode round logic
- **No backgrounds** - Removed 7.8MB menu images

## 📁 File Structure

```
zcity_optimized/
├── addon.txt                 # Workshop info
├── gamemode.txt              # Gamemode info
├── lua/
│   └── autorun/
│       └── zc_autorun.lua    # Sandbox addon entry
└── gamemode/
    ├── init.lua              # Server entry
    ├── cl_init.lua           # Client entry
    ├── shared.lua            # Shared core
    ├── cl_loader.lua         # Client file loader
    ├── sv_loader.lua         # Server file loader
    ├── libraries/
    │   ├── sh_util.lua       # Math/string/table/entity helpers
    │   ├── sh_net.lua        # Compressed networking
    │   └── sh_config.lua     # ConVar system with validation
    ├── systems/
    │   ├── sh_organism.lua   # Health/stamina/injuries
    │   ├── sh_inventory.lua  # Grid inventory + items
    │   ├── sh_movement.lua   # Prone/lean/slide/vault
    │   └── sh_equipment.lua  # Clothing/armor/backpacks
    ├── weapons/
    │   ├── sh_base.lua       # Weapon base class
    │   ├── weapon_pistol.lua # Glock 17 example
    │   └── weapon_rifle.lua  # M4A1 example
    └── ui/
        ├── cl_inventory.lua  # Inventory menu
        └── cl_hud.lua        # HUD + hitmarkers
```

## 🔧 Adding Custom Weapons

```lua
-- weapons/weapon_mygun.lua
AddCSLuaFile()

SWEP.Base = "zc_weapon_base"
SWEP.PrintName = "My Gun"
SWEP.Category = "ZCity Optimized - Custom"
SWEP.Spawnable = true

SWEP.ViewModel = "models/weapons/c_custom.mdl"
SWEP.WorldModel = "models/weapons/w_custom.mdl"

SWEP.Primary = {
    Ammo = "smg1",
    ClipSize = 30,
    Damage = 30,
    RPM = 700,
    -- ... other stats
}

SWEP.Attachments = {
    [1] = {slot = "optic", options = {"att_optic_reddot"}},
    [2] = {slot = "muzzle", options = {"att_suppressor"}},
}

function SWEP:ResetToBaseStats()
    self.Primary.Damage = 30
    self.Primary.Spread = 0.01
    -- reset to defaults
end
```

## 🔧 Adding Custom Items

```lua
-- In any shared file
hg.Inventory.RegisterItem("my_item", {
    name = "My Item",
    desc = "Does something cool",
    model = "models/props/...",
    weight = 1.0,
    stack = 5,
    type = "consumable",
    use = function(ply, item)
        ply:ChatPrint("Used " .. item.class)
        return true
    end,
})
```

## 📈 Size Comparison

| Component | Original | Optimized | Reduction |
|-----------|----------|-----------|-----------|
| **Total** | 34 MB | ~3 MB | **91%** |
| Backgrounds | 7.8 MB | 0 MB | 100% |
| Weapons | 2.2 MB | 50 KB | 98% |
| Game Modes | 860 KB | 0 KB | 100% |
| Homigrad | 2.8 MB | 200 KB | 93% |
| Core Systems | - | 300 KB | New |

## 🐛 Console Commands

| Command | Description |
|---------|-------------|
| `zc_reload` | Reload addon (client & server) |
| `zc_reload_cl` | Reload client files |
| `zc_reload_sv` | Reload server files (admin) |
| `zc_org_heal <amount>` | Heal target (admin) |
| `zc_org_damage <amount>` | Damage target (admin) |
| `zc_org_debug` | Print organism data (admin) |
| `zc_inv_give <class> <count>` | Give item (admin) |
| `zc_inv_clear` | Clear inventory (admin) |
| `zc_inv_debug` | Print inventory (admin) |
| `zc_eq_give <class> <slot>` | Equip item (admin) |
| `zc_eq_remove <slot>` | Unequip slot (admin) |
| `zc_eq_debug` | Print equipment (admin) |
| `zc_mov_debug` | Print movement data (admin) |

## 📝 License

MIT License - Based on Z-City by uzelezz, sadsalat, Mr. Point, Zac90, Deka, Mannytko

## 🤝 Credits

- **Original Z-City Team** - Base systems and concepts
- **Optimized Fork** - Refactoring, optimization, Sandbox adaptation

---

**Note:** This is a **fork**, not the original Z-City. It removes all round-based game modes (TDM, Homicide, Coop, etc.) and focuses purely on Sandbox gameplay with realistic systems.