extends Node
class_name HealthRegenComponent

## Handles health regeneration over time
## Automatically connects to HealthComponent if present

@export var base_regen_per_second: float = 0.0  # Base regeneration rate
@export var health_component_path: NodePath = NodePath("../HealthComponent")

var health_component: HealthComponent = null
var current_regen_rate: float = 0.0
var regen_timer: float = 0.0

func _ready() -> void:
	# Find health component
	if has_node(health_component_path):
		health_component = get_node(health_component_path) as HealthComponent
	
	current_regen_rate = base_regen_per_second

func _process(delta: float) -> void:
	if not health_component or current_regen_rate <= 0.0:
		return
	
	# Don't regenerate if already at max health
	if health_component.current_health >= health_component.max_health:
		return
	
	# Accumulate regeneration
	regen_timer += delta
	
	# Regenerate 1 health per tick
	while regen_timer >= 1.0 / current_regen_rate:
		regen_timer -= 1.0 / current_regen_rate
		health_component.heal(1)

func set_regen_rate(rate: float) -> void:
	"""Set the regeneration rate (health per second)"""
	current_regen_rate = rate

func get_regen_rate() -> float:
	"""Get the current regeneration rate"""
	return current_regen_rate

func add_regen(amount: float) -> void:
	"""Add to the regeneration rate"""
	current_regen_rate += amount
	if current_regen_rate < 0:
		current_regen_rate = 0

func multiply_regen(multiplier: float) -> void:
	"""Multiply the regeneration rate"""
	current_regen_rate *= multiplier
	if current_regen_rate < 0:
		current_regen_rate = 0
