extends Camera2D

@export var target: Node2D
@export var follow_lerp_speed: float = 8.0
@export var enable_smoothing: bool = false
@export var snap_to_pixels: bool = true

# Optional zoom controls. Change or remove if you already have your own.
@export var enable_zoom_input: bool = true
@export var min_zoom: float = 0.5
@export var max_zoom: float = 4.0
@export var zoom_step: float = 0.1

func _ready() -> void:

	if target == null:
		var t := get_tree().get_first_node_in_group("trawler")
		if t is Node2D:
			target = t

func _process(delta: float) -> void:
	var new_pos: Vector2 = global_position

	if target != null:
		if enable_smoothing:
			new_pos = global_position.lerp(target.global_position, follow_lerp_speed * delta)
		else:
			new_pos = target.global_position

	if snap_to_pixels:
		new_pos = new_pos.round()

	global_position = new_pos

func _unhandled_input(event: InputEvent) -> void:
	if not enable_zoom_input:
		return

	# Replace this whole block with your own zoom logic if you already had one.
	if event is InputEventMouseButton and event.pressed:
		var factor: float = 1.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			factor = 1.0 - zoom_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			factor = 1.0 + zoom_step
		else:
			return

		var new_zoom: Vector2 = zoom * factor
		var z: float = clamp(new_zoom.x, min_zoom, max_zoom)
		zoom = Vector2(z, z)
