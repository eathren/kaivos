extends Sprite2D
class_name GoStick

## GoStick - Interactive lever to control the Trawler's movement state
## Left = STOP, Up = GO, Right = BURST (turbo)

signal state_changed(new_state: int)

enum StickState {
	LEFT_STOP = 0,    # Stopped
	UP_GO = 1,        # Normal speed
	RIGHT_BURST = 2   # Turbo mode
}

@export var interaction_key: String = "interact"  # Default E key
@export var rotation_speed: float = 5.0  # How fast the stick rotates

var current_stick_state: StickState = StickState.UP_GO
var target_rotation_degrees: float = -90.0  # Up position
var player_in_range: bool = false
var nearby_player: Node = null

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_label: Label = $InteractionLabel

# Rotation angles for each state
const ROTATION_LEFT: float = -180.0  # Points left
const ROTATION_UP: float = -90.0     # Points up
const ROTATION_RIGHT: float = 0.0    # Points right

func _ready() -> void:
	# Connect interaction area signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	# Hide interaction label initially
	if interaction_label:
		interaction_label.visible = false
	
	# Set initial rotation
	rotation_degrees = target_rotation_degrees
	
	# Emit initial state
	state_changed.emit(current_stick_state)

func _process(delta: float) -> void:
	# Smoothly rotate to target angle
	rotation_degrees = lerp(rotation_degrees, target_rotation_degrees, rotation_speed * delta)
	
	# Check for interaction input
	if player_in_range and Input.is_action_just_pressed(interaction_key):
		_cycle_state()

func _cycle_state() -> void:
	# Cycle through states: STOP -> GO -> BURST -> STOP
	current_stick_state = (current_stick_state + 1) % 3
	
	# Update target rotation based on new state
	match current_stick_state:
		StickState.LEFT_STOP:
			target_rotation_degrees = ROTATION_LEFT
		StickState.UP_GO:
			target_rotation_degrees = ROTATION_UP
		StickState.RIGHT_BURST:
			target_rotation_degrees = ROTATION_RIGHT
	
	# Emit signal
	state_changed.emit(current_stick_state)
	print("GoStick: State changed to ", StickState.keys()[current_stick_state])

func _on_body_entered(body: Node) -> void:
	# Check if it's a player or crew member
	if body.is_in_group("player") or body.is_in_group("crew"):
		player_in_range = true
		nearby_player = body
		if interaction_label:
			interaction_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body == nearby_player:
		player_in_range = false
		nearby_player = null
		if interaction_label:
			interaction_label.visible = false

func get_current_state() -> StickState:
	return current_stick_state

func set_state(new_state: StickState) -> void:
	if current_stick_state != new_state:
		current_stick_state = new_state
		
		match current_stick_state:
			StickState.LEFT_STOP:
				target_rotation_degrees = ROTATION_LEFT
			StickState.UP_GO:
				target_rotation_degrees = ROTATION_UP
			StickState.RIGHT_BURST:
				target_rotation_degrees = ROTATION_RIGHT
		
		state_changed.emit(current_stick_state)
