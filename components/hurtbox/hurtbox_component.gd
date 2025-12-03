extends Area2D
class_name HurtboxComponent

## Detects incoming damage from enemy attacks and touch damage
## Automatically connects to HealthComponent if present

signal hit_received(damage: int, attacker: Node)

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var invulnerability_time: float = 0.5  # Time between damage instances

var health_component: HealthComponent = null
var invulnerable: bool = false
var invulnerable_timer: float = 0.0
var parent_node: Node2D = null

func _ready() -> void:
	# Set collision layers
	collision_layer = 0  # Don't be detected by others
	collision_mask = 8  # Detect enemy damage areas (layer 8)
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	
	# Get parent
	parent_node = get_parent() as Node2D
	
	# Find health component
	if has_node(health_component_path):
		health_component = get_node(health_component_path) as HealthComponent

func _process(delta: float) -> void:
	if invulnerable:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0:
			invulnerable = false
			_reset_visual_effect()
		else:
			_apply_visual_effect()

func _on_area_entered(area: Area2D) -> void:
	"""Handle damage from enemy damage areas"""
	if invulnerable:
		return
	
	# Check if it's an enemy damage area
	var attacker = area.get_parent()
	var damage_component = attacker.get_node_or_null("TouchDamageComponent")
	
	if damage_component and damage_component.has_method("can_damage_target"):
		if damage_component.can_damage_target(parent_node):
			var damage = damage_component.get_damage()
			damage_component.record_damage(parent_node)
			take_damage(damage, attacker)

func take_damage(amount: int, attacker: Node = null) -> void:
	"""Apply damage to health component"""
	if invulnerable:
		return
	
	# Apply damage to health component
	if health_component:
		health_component.take_damage(amount)
		print("%s took %d damage! Health: %d/%d" % [parent_node.name, amount, health_component.current_health, health_component.max_health])
	
	# Emit signal
	hit_received.emit(amount, attacker)
	
	# Start invulnerability
	if invulnerability_time > 0:
		invulnerable = true
		invulnerable_timer = invulnerability_time

func _apply_visual_effect() -> void:
	"""Flash effect during invulnerability"""
	if not parent_node:
		return
	
	# Flash between translucent and opaque
	if int(invulnerable_timer * 10) % 2 == 0:
		parent_node.modulate = Color(1, 1, 1, 0.5)
	else:
		parent_node.modulate = Color.WHITE

func _reset_visual_effect() -> void:
	"""Reset visual state after invulnerability"""
	if parent_node:
		parent_node.modulate = Color.WHITE

func set_invulnerable(value: bool) -> void:
	"""Manually set invulnerability state"""
	invulnerable = value
	if not value:
		_reset_visual_effect()
