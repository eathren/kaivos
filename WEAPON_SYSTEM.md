# Weapon System - Vampire Survivors Style

## Overview
A flexible, data-driven weapon system supporting multiple simultaneous weapons, stackable modifiers, and synergies.

## Architecture

```
WeaponData (.tres) → WeaponInstance (runtime) → WeaponManager (component) → Auto-fires
     ↓
ModifierData (.tres) → Applied to all weapons → Stacking multipliers
     ↓
SynergyData (.tres) → Checks conditions → Activates special combos
```

## Core Components

### 1. WeaponData (Resource)
Defines a weapon's base stats and scaling.

**Key Properties:**
- `weapon_type`: BULLET, LASER, SAWBLADE, MISSILE, WAVE, ORBIT
- `fire_pattern`: FORWARD, SPREAD, SPIRAL, BURST, STREAM, ORBIT
- `base_damage`, `base_fire_rate`, `base_projectile_count`
- `damage_per_level`, `fire_rate_per_level`
- `evolution_weapon`: What it evolves into at max level
- `projectile_scene`: The bullet/projectile to spawn

### 2. WeaponInstance (Runtime)
Tracks a weapon's current state.

**Key Features:**
- Current level (1-7 typically)
- Calculated stats after modifiers
- Cooldown tracking
- `apply_modifiers()` - recalculates with all active buffs

### 3. WeaponManager (Component)
Manages all active weapons on a ship.

**Key Methods:**
- `add_weapon(weapon_data)` - Adds new or levels up existing
- `add_modifier(modifier_data)` - Adds passive buff
- Auto-fires all weapons based on their cooldowns

### 4. ModifierData (Resource)
Passive upgrades that buff weapons.

**Types:**
- DAMAGE_MULTIPLIER - +X% damage
- FIRE_RATE_MULTIPLIER - +X% fire rate
- PROJECTILE_SPEED - +X% speed
- PIERCE - +X pierce count
- CRIT_CHANCE, CRIT_DAMAGE
- RANGE, AREA, DURATION

**Filtering:**
- Can affect all weapons
- Can target specific weapon types
- Can target specific weapon names

### 5. SynergyData (Resource)
Special bonuses when conditions are met.

**Examples:**
- "Twin Flames" - Having Fireball + Laser = double projectiles
- "Critical Mass" - 3+ crit modifiers = explosions on crit
- "Bullet Hell" - 4+ weapons active = +50% all stats

## How to Use

### Add to Player Ship:
```gdscript
# Add WeaponManager component to player ship scene
@onready var weapon_manager: WeaponManager = $WeaponManager

func _ready():
    weapon_manager.owner_ship = self
```

### Add Weapons:
```gdscript
# Load weapon data
var basic_gun = preload("res://resources/config/weapons/basic_gun.tres")
weapon_manager.add_weapon(basic_gun)

# Adding again levels it up
weapon_manager.add_weapon(basic_gun)  # Now level 2
```

### Add Modifiers:
```gdscript
var damage_boost = preload("res://resources/config/modifiers/damage_boost.tres")
weapon_manager.add_modifier(damage_boost)

# All weapons now do +15% damage
```

### Create New Weapons:

1. **Create WeaponData resource:**
```
Right-click → New Resource → WeaponData
Set properties in Inspector
Save as .tres file
```

2. **Create projectile scene:**
```
Create Node2D with:
- Sprite
- CollisionShape2D (for Area2D)
- Script with: damage, speed, pierce properties
- lifetime timer
```

3. **Assign projectile to weapon:**
```
In WeaponData .tres:
- Set projectile_scene to your projectile.tscn
```

## Example Weapons

### Basic Gun
- Type: BULLET
- Pattern: FORWARD
- Fire Rate: 2/sec
- Damage: 10 + 5/level
- Good for consistent DPS

### Sawblade
- Type: SAWBLADE
- Pattern: STREAM
- Pierce: 999 (goes through everything)
- Damage: 25 + 10/level
- Slow but piercing

### Laser
- Type: LASER
- Pattern: FORWARD
- Duration: Continuous
- Damage: 5/tick
- Constant damage beam

### Orbit Shield
- Type: ORBIT
- Pattern: ORBIT
- Spins around ship
- Damage: Contact damage
- Protection + offense

## Example Modifiers

### Offensive
- Damage Boost (+15% damage)
- Rapid Fire (+20% fire rate)
- Critical Strike (+10% crit chance)
- Piercing Rounds (+1 pierce)

### Utility
- Speed Boost (+15% movement)
- Pickup Range (+50% range)
- Health Regen (+2 HP/sec)

### Special
- Multishot (+1 projectile)
- Ricochet (bullets bounce)
- Explosive Rounds (AoE on hit)

## Example Synergies

### "Gatling Mode"
**Requirements:** Basic Gun level 7 + Rapid Fire x3
**Effect:** +100% fire rate, -50% damage per shot, +3 projectiles

### "Death Beam"
**Requirements:** Laser + Damage Boost x5
**Effect:** Laser gains pierce, +50% width

### "Buzzsaw"
**Requirements:** Sawblade + Rapid Fire
**Effect:** Sawblades orbit the ship instead of flying forward

## Evolution System

At max level (7), weapons can evolve:

```
Basic Gun → Plasma Rifle (requires Energy Cell item)
Sawblade → Buzzsaw Storm (requires Spin Modifier)
Laser → Death Ray (requires Focus Lens)
```

Evolutions are new weapons with enhanced stats and special properties.

## Integration with GameState

```gdscript
# Store unlocked weapons globally
GameState.unlocked_weapons: Array[String] = ["Basic Gun", "Sawblade"]

# Store persistent modifiers
GameState.persistent_modifiers: Array[ModifierData] = []

# On ship spawn, load from GameState
for weapon_name in GameState.unlocked_weapons:
    var weapon_data = load("res://resources/config/weapons/" + weapon_name.to_lower() + ".tres")
    weapon_manager.add_weapon(weapon_data)
```

## Level-Up Flow

```gdscript
# On XP level up, show upgrade choices
func show_upgrade_choices():
    var choices = [
        random_weapon(),
        random_weapon(),
        random_modifier()
    ]
    
    # Player picks one
    var choice = await upgrade_ui.show_choices(choices)
    
    if choice is WeaponData:
        weapon_manager.add_weapon(choice)
    elif choice is ModifierData:
        weapon_manager.add_modifier(choice)
```

## Performance Tips

1. **Object Pooling** for projectiles
2. **Limit active projectiles** (e.g. max 200)
3. **Use collision layers** efficiently
4. **Batch similar weapons** (fire multiple at once)

## Chaos Examples (Binding of Isaac style)

### "Homing Explosive Piercing Lasers"
- Base: Laser weapon
- +Homing modifier
- +Explosive modifier
- +Pierce modifier
= Laser that curves toward enemies, explodes on hit, pierces through

### "Infinite Ricochet Bullets"
- Base: Basic Gun
- +Multishot x5
- +Ricochet modifier
- +Piercing modifier
= 5 bullets that bounce between enemies infinitely

This system supports crazy combinations while keeping data organized!

