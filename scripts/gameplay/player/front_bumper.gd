@onready var laser: RayCast2D = $LaserRaycast

func _process(delta: float) -> void:
	var firing := Input.is_action_pressed("left_click")
	laser.is_casting = firing
