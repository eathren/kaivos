extends Node
class_name TouchDamageComponent

## Component that handles touch damage for enemies

@export var damage: int = 10
@export var damage_cooldown: float = 1.0  # Time between damage ticks

var last_damage_time: Dictionary = {}  # target -> timestamp
var scaled_damage: int = 0  # Set by parent's apply_level() if needed

func get_damage() -> int:
	# Use scaled damage if set, otherwise base damage
	return scaled_damage if scaled_damage > 0 else damage

func set_scaled_damage(amount: int) -> void:
	"""Called by enemy when apply_level() bakes in stats"""
	scaled_damage = amount

func can_damage_target(target: Node) -> bool:
	"""Check if enough time has passed to damage this target again"""
	if not last_damage_time.has(target):
		return true
	
	var time_since_last = Time.get_ticks_msec() / 1000.0 - last_damage_time[target]
	return time_since_last >= damage_cooldown

func record_damage(target: Node) -> void:
	"""Record that we damaged this target"""
	last_damage_time[target] = Time.get_ticks_msec() / 1000.0
