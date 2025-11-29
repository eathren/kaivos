extends Resource
class_name SynergyData

## Defines synergies between weapons/modifiers

enum SynergyType {
	WEAPON_COMBO,         # Having 2+ specific weapons
	MODIFIER_COMBO,       # Having 2+ specific modifiers
	WEAPON_MODIFIER_COMBO,# Specific weapon + modifier
	WEAPON_LEVEL,         # Weapon at certain level
}

@export var synergy_name: String = "Twin Flames"
@export var synergy_type: SynergyType = SynergyType.WEAPON_COMBO

# Requirements
@export var required_weapons: Array[String] = []  # Weapon names
@export var required_modifiers: Array[String] = []  # Modifier names
@export var required_weapon_level: int = 0

# Effects (applied when synergy is active)
@export var bonus_damage_multiplier: float = 1.0
@export var bonus_fire_rate_multiplier: float = 1.0
@export var bonus_projectile_count: int = 0
@export var grants_special_behavior: bool = false
@export var special_behavior_script: GDScript = null

@export var description: String = "Having Fireball + Laser creates twin projectiles"
@export var icon: Texture2D

