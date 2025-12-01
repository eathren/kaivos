extends Camera2D
class_name ShakeCamera

## Camera with trauma-based screen shake

@export var max_offset: float = 8.0
@export var max_rotation: float = 0.05
@export var decay: float = 1.5

var trauma: float = 0.0

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return

	trauma = max(trauma - decay * delta, 0.0)
	var t = trauma * trauma

	offset.x = randf_range(-1.0, 1.0) * max_offset * t
	offset.y = randf_range(-1.0, 1.0) * max_offset * t
	rotation = randf_range(-1.0, 1.0) * max_rotation * t
