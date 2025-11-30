# Testing the New Weapon System

## What's Integrated:

✅ Player ship now has `WeaponManager`  
✅ Starts with `Basic Gun` weapon  
✅ Bullets auto-fire every 0.5 seconds (2 shots/sec)  
✅ Bullets spawn from ship position, fly forward  
✅ Bullets have pierce support (0 by default)  
✅ Bullets damage enemies based on faction  

## How to Test:

### 1. Run the Game
- Undock a ship from the trawler (press E near ladder)
- Ship will auto-fire bullets forward continuously
- Bullets fire in the direction ship is facing

### 2. Test Weapon Leveling (In Console)
```gdscript
# Get the player ship
var ship = get_tree().get_first_node_in_group("player_ship")

# Level up the gun
var basic_gun = preload("res://resources/config/weapons/basic_gun.tres")
ship.weapon_manager.add_weapon(basic_gun)  # Levels up to 2

# Check current stats
for weapon in ship.weapon_manager.active_weapons:
    print("Weapon: ", weapon.weapon_data.weapon_name)
    print("  Level: ", weapon.current_level)
    print("  Damage: ", weapon.current_damage)
    print("  Fire Rate: ", weapon.current_fire_rate)
```

### 3. Test Modifiers
```gdscript
# Add damage boost
var damage_mod = preload("res://resources/config/modifiers/damage_boost.tres")
ship.weapon_manager.add_modifier(damage_mod)

# Now bullets do +15% more damage!
```

### 4. Add Multiple Weapons
```gdscript
# Add sawblade weapon
var sawblade = preload("res://resources/config/weapons/sawblade.tres")
ship.weapon_manager.add_weapon(sawblade)

# Now ship fires BOTH basic gun AND sawblade simultaneously!
```

## Current Weapon Stats:

### Basic Gun (Level 1)
- Damage: 10
- Fire Rate: 2/sec
- Projectiles: 1
- Speed: 400
- Pierce: 0

### Sawblade (Level 1)
- Damage: 25
- Fire Rate: 0.5/sec
- Projectiles: 1
- Speed: 300
- Pierce: 999 (goes through everything)

## Adding New Weapons:

1. **Create weapon .tres:**
   - Duplicate `basic_gun.tres`
   - Edit stats in Godot Inspector
   - Set `projectile_scene` to bullet.tscn or create custom projectile

2. **Create custom projectile** (optional):
   - Must have: `damage`, `speed`, `pierce`, `lifetime`, `faction` properties
   - Must move itself
   - Must handle collisions

3. **Add to ship:**
   ```gdscript
   var new_weapon = preload("res://resources/config/weapons/my_weapon.tres")
   weapon_manager.add_weapon(new_weapon)
   ```

## Expected Behavior:

- Ship spawns with Basic Gun
- Auto-fires forward every 0.5 seconds
- Bullets damage enemies on hit
- Can add more weapons for multi-weapon mayhem!

## Next Steps:

- Create more weapon types (missiles, lasers, waves)
- Create level-up UI to choose upgrades
- Implement synergies
- Add evolution system

