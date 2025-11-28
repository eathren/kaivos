extends Node
class_name WeaponComponent

## Manages weapons and upgrades for player ships
## Reads weapon data from GameState for consistent upgrades across all ships

signal weapon_fired(weapon_type: String)
signal weapon_upgraded(weapon_type: String, level: int)

@export var fire_rate: float = 0.5  # Base fire rate in seconds
@export var auto_fire: bool = false  # Auto-fire when enemies in range

var _fire_timer: float = 0.0
var _current_target: Node2D = null

# Weapon types available
enum WeaponType {
	LASER,
	BULLET,
	MISSILE,
	BEAM
}

var active_weapons: Array[int] = [WeaponType.LASER]  # Start with laser (stored as int for GameState compatibility)

func _ready() -> void:
	# Load weapon configuration from GameState
	_load_weapon_state()

func _process(delta: float) -> void:
	_fire_timer += delta

func _load_weapon_state() -> void:
	"""Load current weapon upgrades from GameState"""
	if not GameState:
		return
	
	# Get weapon unlocks from GameState
	if GameState.has_method("get_unlocked_weapons"):
		active_weapons = GameState.get_unlocked_weapons()
	
	# Get fire rate multiplier from upgrades
	if GameState.has_method("get_fire_rate_multiplier"):
		var multiplier: float = GameState.get_fire_rate_multiplier()
		fire_rate = fire_rate / multiplier  # Higher multiplier = faster fire rate

func can_fire() -> bool:
	"""Check if enough time has passed to fire again"""
	return _fire_timer >= fire_rate

func fire_at_target(target: Node2D, origin: Node2D) -> void:
	"""Fire weapons at a target"""
	if not can_fire():
		return
	
	_fire_timer = 0.0
	_current_target = target
	
	# Fire each active weapon type
	for weapon_type in active_weapons:
		_fire_weapon(weapon_type, target, origin)

func _fire_weapon(weapon_type: int, target: Node2D, origin: Node2D) -> void:
	"""Fire a specific weapon type"""
	match weapon_type:
		WeaponType.LASER:
			_fire_laser(target, origin)
		WeaponType.BULLET:
			_fire_bullet(target, origin)
		WeaponType.MISSILE:
			_fire_missile(target, origin)
		WeaponType.BEAM:
			_fire_beam(target, origin)
	
	weapon_fired.emit(str(weapon_type))

func _fire_laser(target: Node2D, origin: Node2D) -> void:
	"""Laser is handled by Laser nodes on the ship"""
	pass  # Lasers are always-on beams, handled separately

func _fire_bullet(target: Node2D, origin: Node2D) -> void:
	"""Fire a bullet projectile"""
	# TODO: Implement bullet spawning when bullet scene exists
	pass

func _fire_missile(target: Node2D, origin: Node2D) -> void:
	"""Fire a homing missile"""
	# TODO: Implement missile spawning when missile scene exists
	pass

func _fire_beam(target: Node2D, origin: Node2D) -> void:
	"""Fire a continuous beam weapon"""
	# TODO: Implement beam weapon
	pass

func get_weapon_damage() -> float:
	"""Get total weapon damage from GameState"""
	if GameState and GameState.has_method("get_weapon_damage_multiplier"):
		return 15.0 * GameState.get_weapon_damage_multiplier()
	return 15.0

func upgrade_weapon(weapon_type: int) -> void:
	"""Called when a weapon is upgraded"""
	_load_weapon_state()  # Reload from GameState
	weapon_upgraded.emit(str(weapon_type), 1)
