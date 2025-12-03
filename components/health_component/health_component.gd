extends Node
class_name HealthComponent

@export var max_health: int = 100
@export var show_damage_numbers: bool = true
var current_health: int

signal health_changed(current: int, max: int)
signal died

var damage_number_scene: PackedScene = preload("res://ui/damage_numbers/damage_number.tscn")

func _ready() -> void:
	current_health = max_health

func apply_damage(amount: int, is_crit: bool = false, is_megacrit: bool = false) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health -= amount
	if current_health < 0:
		current_health = 0

	health_changed.emit(current_health, max_health)
	
	# Spawn damage number
	if show_damage_numbers:
		_spawn_damage_number(amount, is_crit, is_megacrit)

	if current_health == 0:
		died.emit()

## Alias for compatibility
func take_damage(amount: float, is_crit: bool = false, is_megacrit: bool = false) -> void:
	apply_damage(int(amount), is_crit, is_megacrit)

func _spawn_damage_number(amount: int, is_crit: bool, is_megacrit: bool) -> void:
	"""Spawn a floating damage number above the entity"""
	if not damage_number_scene:
		return
	
	var parent = get_parent()
	if not parent:
		return
	
	var damage_num = damage_number_scene.instantiate() as Node2D
	if not damage_num:
		return
	
	# Determine damage type
	var damage_type = DamageNumber.DamageType.NORMAL
	if is_megacrit:
		damage_type = DamageNumber.DamageType.MEGACRIT
	elif is_crit:
		damage_type = DamageNumber.DamageType.CRIT
	
	damage_num.setup(amount, damage_type)
	damage_num.global_position = parent.global_position + Vector2(0, -16)
	
	# Add to level root (not to the enemy, in case it dies)
	var level = get_tree().current_scene
	if level:
		level.add_child(damage_num)

func heal(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health += amount
	if current_health > max_health:
		current_health = max_health

	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0
