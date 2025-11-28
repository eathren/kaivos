extends CharacterBody2D

## Player ship with two small lasers and movement
## Lasers toggle on/off with interact button

signal lasers_toggled(is_on: bool)

@export var speed: float = 150.0
@export var turret_range: float = 300.0
@export var turret_fire_rate: float = 0.2  # Seconds between shots

@onready var left_laser: Laser = $LeftLaser
@onready var right_laser: Laser = $RightLaser
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var frame_sprite: Sprite2D = $Sprite2D
@onready var weapon_component: Node = $WeaponComponent

var lasers_enabled: bool = false
var is_active: bool = false
var is_turret_mode: bool = false  # True when docked as turret
var player_reference: CharacterBody2D = null  # Reference to the crew member inside trawler
var can_dock: bool = false  # Prevent immediate re-docking
var dock_cooldown: float = 2.0  # Seconds before you can dock again

# Turret mode variables
var _turret_target: Node2D = null
var _turret_fire_timer: float = 0.0

func _ready() -> void:
	# Start with lasers off
	_update_lasers()
	
	add_to_group("player")
	add_to_group("player_ship")
	
	# Apply speed multiplier from GameState
	if GameState and GameState.has_method("get_ship_speed_multiplier"):
		speed *= GameState.get_ship_speed_multiplier()
	
	# Update weapon component with GameState data
	if weapon_component and weapon_component.has_method("_load_weapon_state"):
		weapon_component._load_weapon_state()

func _physics_process(delta: float) -> void:
	if is_turret_mode:
		_handle_turret_mode(delta)
		return
	
	if not is_active:
		return
	
	# Handle rotation (face mouse or gamepad right stick)
	_handle_rotation(delta)
	
	# Handle movement (WASD - independent of rotation)
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _handle_rotation(delta: float) -> void:
	# Rotate to face mouse (or gamepad right stick)
	var aim_dir := Vector2.ZERO
	
	# Mouse aiming (primary)
	var mouse_pos := get_global_mouse_position()
	aim_dir = (mouse_pos - global_position).normalized()
	
	# Gamepad right stick override (if being used)
	var gamepad_aim := Vector2.ZERO
	gamepad_aim.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	gamepad_aim.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if gamepad_aim.length() > 0.2:  # Deadzone
		aim_dir = gamepad_aim.normalized()
	
	# Rotate to face aim direction
	if aim_dir != Vector2.ZERO:
		var target_rotation := aim_dir.angle() + PI / 2.0  # +90 degrees because sprite faces up by default
		rotation = lerp_angle(rotation, target_rotation, 15.0 * delta)  # Smooth rotation

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event.is_action_pressed("interact"):
		lasers_enabled = not lasers_enabled
		_update_lasers()
		lasers_toggled.emit(lasers_enabled)

func _update_lasers() -> void:
	if left_laser:
		left_laser.set_is_casting(lasers_enabled)
	if right_laser:
		right_laser.set_is_casting(lasers_enabled)

func take_control_from_player(player: CharacterBody2D) -> void:
	"""Called when player boards this ship from the trawler"""
	player_reference = player
	is_active = true
	can_dock = false  # Start with docking disabled
	
	print("Ship: Taking control from player")
	
	# Move camera from player to ship
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		player.remove_child(camera)
		add_child(camera)
		camera.position = Vector2.ZERO
		camera.make_current()
		print("Ship: Camera transferred to ship")
	
	# Enable docking after cooldown (check if still valid)
	await get_tree().create_timer(dock_cooldown).timeout
	if is_instance_valid(self) and is_active:
		can_dock = true
		print("Ship: Can now dock back at trawler")

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Check for docking back at ship dock (only after cooldown)
	if can_dock:
		var nearest_dock := _find_nearest_available_dock()
		if nearest_dock:
			var distance := global_position.distance_to(nearest_dock.global_position)
			if distance < 100.0:
				# Show UI prompt for docking
				var ui := get_tree().root.get_node_or_null("Main/UI/InteractionPrompt")
				if ui and ui.has_method("show_interaction_prompt"):
					ui.show_interaction_prompt("Press E to dock ship")
				
				if Input.is_action_just_pressed("interact"):
					return_to_dock(nearest_dock)
			else:
				# Hide prompt when too far
				var ui := get_tree().root.get_node_or_null("Main/UI/InteractionPrompt")
				if ui and ui.has_method("hide_interaction_prompt"):
					ui.hide_interaction_prompt()
		else:
			# No available docks - hide prompt
			var ui := get_tree().root.get_node_or_null("Main/UI/InteractionPrompt")
			if ui and ui.has_method("hide_interaction_prompt"):
				ui.hide_interaction_prompt()

func set_turret_mode(enabled: bool) -> void:
	"""Enable/disable turret mode - auto-targeting and shooting"""
	is_turret_mode = enabled
	is_active = not enabled  # Turret mode means not player-controlled
	
	if enabled:
		# Turret mode: hide player sprite, disable lasers initially
		if player_sprite:
			player_sprite.visible = false
		lasers_enabled = false
		_update_lasers()
		print("Ship: Turret mode ENABLED")
	else:
		# Manual control: show player sprite, disable lasers
		if player_sprite:
			player_sprite.visible = true
		lasers_enabled = false
		_update_lasers()
		_turret_target = null
		print("Ship: Turret mode DISABLED")

func _handle_turret_mode(delta: float) -> void:
	"""Auto-target and shoot at enemies when in turret mode"""
	_turret_fire_timer += delta
	
	# Find nearest enemy
	_turret_target = _find_nearest_enemy()
	
	if _turret_target and is_instance_valid(_turret_target):
		# Rotate to face target
		var target_dir := global_position.direction_to(_turret_target.global_position)
		var target_rotation := target_dir.angle() + PI / 2.0
		rotation = lerp_angle(rotation, target_rotation, 10.0 * delta)
		
		# Use weapon component to determine fire rate
		var can_fire := true
		if weapon_component and weapon_component.has_method("can_fire"):
			can_fire = weapon_component.can_fire()
		
		# Turn on lasers when weapon component says we can fire
		if can_fire:
			_turret_fire_timer = 0.0
			# Fire weapons
			if weapon_component and weapon_component.has_method("fire_at_target"):
				weapon_component.fire_at_target(_turret_target, self)
			# Brief laser burst
			lasers_enabled = true
			_update_lasers()
	else:
		# No target - turn off lasers
		if lasers_enabled:
			lasers_enabled = false
			_update_lasers()

func _find_nearest_enemy() -> Node2D:
	"""Find the nearest enemy within turret range"""
	var enemies := get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist := turret_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist
	
	return nearest

func _find_nearest_available_dock() -> Node2D:
	"""Find the nearest ship dock that is available"""
	var ship_docks := get_tree().get_nodes_in_group("ship_dock")
	var nearest: Node2D = null
	var nearest_dist := INF
	
	for dock in ship_docks:
		if not is_instance_valid(dock):
			continue
		
		# Check if dock is available
		if dock.has_method("is_occupied") and dock.is_occupied():
			continue
		
		var dist := global_position.distance_to(dock.global_position)
		if dist < nearest_dist:
			nearest = dock
			nearest_dist = dist
	
	return nearest

func return_to_dock(dock: Node2D) -> void:
	"""Called when ship docks back at a ship dock"""
	if player_reference == null:
		print("Ship: No player reference, cannot dock")
		return
	
	print("Ship: Starting docking sequence at dock - ", dock.name)
	
	# Immediately disable all processing to prevent race conditions
	set_physics_process(false)
	set_process(false)
	set_process_input(false)
	is_active = false
	can_dock = false
	
	# Hide dock prompt
	var ui := get_tree().root.get_node_or_null("Main/UI/InteractionPrompt")
	if ui and ui.has_method("hide_interaction_prompt"):
		ui.hide_interaction_prompt()
	
	# Move camera back to player FIRST
	if has_node("Camera2D"):
		var camera = get_node("Camera2D")
		remove_child(camera)
		player_reference.add_child(camera)
		camera.position = Vector2.ZERO
		camera.make_current()
		print("Ship: Camera transferred back to player")
	
	# Reactivate the crew member
	player_reference.activate()
	print("Ship: Player reactivated")
	
	# Dock the ship at the dock
	if dock.has_method("dock_ship"):
		dock.dock_ship(self)
	
	print("Ship: Docked successfully")
