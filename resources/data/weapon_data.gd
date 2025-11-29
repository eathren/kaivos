extends Resource
class_name WeaponData

## Data resource linking weapon stats to a projectile scene

@export var weapon_stats: WeaponStats = null
@export var projectile_scene: PackedScene = null
@export var muzzle_flash: bool = true
@export var fire_sound: AudioStream = null

# Convenience accessors
var weapon_name: String:
	get: return weapon_stats.weapon_name if weapon_stats else "Unknown"

var fire_rate: float:
	get: return weapon_stats.fire_rate if weapon_stats else 0.5

var damage: int:
	get: return weapon_stats.damage if weapon_stats else 10

var projectile_speed: float:
	get: return weapon_stats.projectile_speed if weapon_stats else 600.0

var spread_angle: float:
	get: return weapon_stats.spread_degrees if weapon_stats else 5.0
