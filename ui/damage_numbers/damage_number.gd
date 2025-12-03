extends Node2D
class_name DamageNumber

## Floating damage number that appears above entities when damaged

enum DamageType {
	NORMAL,
	CRIT,
	MEGACRIT
}

var damage_amount: int = 0
var damage_type: DamageType = DamageType.NORMAL
var velocity: Vector2 = Vector2(0, -50)  # Float upward
var lifetime: float = 1.0
var fade_start: float = 0.5

@onready var label: Label = $Label

func _ready() -> void:
	# Set damage text
	label.text = str(damage_amount)
	
	# Set color and size based on damage type
	match damage_type:
		DamageType.NORMAL:
			label.modulate = Color.WHITE
			label.scale = Vector2.ONE
		DamageType.CRIT:
			label.modulate = Color(1.0, 0.3, 0.3)  # Red
			label.scale = Vector2(1.3, 1.3)
		DamageType.MEGACRIT:
			label.modulate = Color(1.0, 0.84, 0.0)  # Gold
			label.scale = Vector2(1.6, 1.6)
	
	# Add random horizontal drift
	velocity.x = randf_range(-20, 20)

func _process(delta: float) -> void:
	# Move upward
	position += velocity * delta
	
	# Slow down over time
	velocity *= 0.95
	
	# Fade out
	lifetime -= delta
	if lifetime <= fade_start:
		var alpha = lifetime / fade_start
		label.modulate.a = alpha
	
	# Remove when expired
	if lifetime <= 0:
		queue_free()

func setup(amount: int, type: DamageType = DamageType.NORMAL) -> void:
	"""Configure the damage number before adding to scene"""
	damage_amount = amount
	damage_type = type
