extends Camera2D

@export var move_speed: float = 600.0
@export var max_pan_distance: float = 300.0   # how far you can drift from the trawler
@export var trawler_path: NodePath

const ZOOM_STEP := 0.1
const MIN_ZOOM := 0.3
const MAX_ZOOM := 5.0

var trawler: Node2D
var pan_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	make_current()
	zoom = Vector2(0.5, 0.5)

	if trawler_path != NodePath():
		trawler = get_node(trawler_path)

func _process(delta: float) -> void:
	if trawler == null:
		return

	_update_pan(delta)
	global_position = trawler.global_position + pan_offset

func _update_pan(delta: float) -> void:
	var dir := Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.y += 1.0

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		pan_offset += dir * move_speed * delta
		if pan_offset.length() > max_pan_distance:
			pan_offset = pan_offset.normalized() * max_pan_distance
	else:
		# ease back toward the trawler when no input
		pan_offset = pan_offset.lerp(Vector2.ZERO, 5.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_out()

func _zoom_in() -> void:
	var new_zoom := zoom.x - ZOOM_STEP
	new_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(new_zoom, new_zoom)

func _zoom_out() -> void:
	var new_zoom := zoom.x + ZOOM_STEP
	new_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(new_zoom, new_zoom)
