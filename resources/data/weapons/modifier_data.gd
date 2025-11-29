extends Resource
class_name ModifierData

## Passive upgrade/modifier that affects weapons or player

enum ModifierType {
	DAMAGE_MULTIPLIER,     # +X% damage to all weapons
	FIRE_RATE_MULTIPLIER,  # +X% fire rate to all weapons
	PROJECTILE_SPEED,      # +X% projectile speed
	PROJECTILE_SIZE,       # +X% projectile size
	PIERCE,                # +X pierce count
	CRIT_CHANCE,           # +X% crit chance
	CRIT_DAMAGE,           # +X% crit damage multiplier
	RANGE,                 # +X% range
	AREA,                  # +X% area of effect
	DURATION,              # +X% duration
	COOLDOWN_REDUCTION,    # -X% cooldown
	MOVEMENT_SPEED,        # +X% movement speed
	PICKUP_RANGE,          # +X% pickup range
	HEALTH,                # +X max health
	HEALTH_REGEN,          # +X health per second
}

@export var modifier_name: String = "Damage Up"
@export var modifier_type: ModifierType = ModifierType.DAMAGE_MULTIPLIER
@export var value: float = 0.1  # 10% increase
@export var stack_additively: bool = true  # If false, stacks multiplicatively
@export var max_stacks: int = 10

# Filtering (which weapons this affects)
@export var affects_all_weapons: bool = true
@export var affected_weapon_types: Array[WeaponData.WeaponType] = []
@export var affected_weapon_names: Array[String] = []

@export var icon: Texture2D
@export var description: String = "+10% Damage to all weapons"

