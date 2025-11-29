extends Node
class_name WeaponInstance

## Runtime instance of a weapon with current stats

var weapon_data: WeaponData
var current_level: int = 1
var cooldown_timer: float = 0.0

# Calculated stats (base + modifiers)
var current_damage: float = 0.0
var current_fire_rate: float = 0.0
var current_projectile_count: int = 0
var current_projectile_speed: float = 0.0
var current_pierce: int = 0
var current_range: float = 0.0
var current_spread_angle: float = 0.0

func _init(data: WeaponData) -> void:
	weapon_data = data
	_recalculate_stats()

func level_up() -> void:
	if current_level >= weapon_data.max_level:
		return
	current_level += 1
	_recalculate_stats()

func _recalculate_stats() -> void:
	"""Recalculate stats based on level and base stats"""
	if not weapon_data:
		return
	
	current_damage = weapon_data.base_damage + (weapon_data.damage_per_level * (current_level - 1))
	current_fire_rate = weapon_data.base_fire_rate + (weapon_data.fire_rate_per_level * (current_level - 1))
	current_projectile_count = weapon_data.base_projectile_count + (weapon_data.projectile_count_per_level * (current_level - 1))
	current_projectile_speed = weapon_data.base_projectile_speed
	current_pierce = weapon_data.base_pierce
	current_range = weapon_data.base_range
	current_spread_angle = weapon_data.base_spread_angle

func apply_modifiers(modifiers: Array) -> void:
	"""Apply all active modifiers to this weapon"""
	_recalculate_stats()
	
	for mod in modifiers:
		if not mod is ModifierData:
			continue
		
		# Check if modifier applies to this weapon
		if not mod.affects_all_weapons:
			if not weapon_data.weapon_type in mod.affected_weapon_types:
				if not weapon_data.weapon_name in mod.affected_weapon_names:
					continue
		
		# Apply modifier
		match mod.modifier_type:
			ModifierData.ModifierType.DAMAGE_MULTIPLIER:
				current_damage *= (1.0 + mod.value)
			ModifierData.ModifierType.FIRE_RATE_MULTIPLIER:
				current_fire_rate *= (1.0 + mod.value)
			ModifierData.ModifierType.PROJECTILE_SPEED:
				current_projectile_speed *= (1.0 + mod.value)
			ModifierData.ModifierType.PIERCE:
				current_pierce += int(mod.value)
			ModifierData.ModifierType.RANGE:
				current_range *= (1.0 + mod.value)

func can_fire() -> bool:
	return cooldown_timer <= 0.0

func update_cooldown(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

func fire() -> void:
	"""Called when weapon fires, resets cooldown"""
	cooldown_timer = 1.0 / current_fire_rate if current_fire_rate > 0 else 1.0

func can_evolve() -> bool:
	return current_level >= weapon_data.max_level and weapon_data.evolution_weapon != null

