extends CharacterBody2D

## Player ship - movement and shooting only
## Docking is handled by PlayerController

# signal lasers_toggled(is_on: bool)  # Unused - commented out

@export var ship_stats: ShipStats = preload("res://resources/config/ships/player_ship_base.tres")

var ship_id: int = -1
var speed: float = 150.0
var is_active: bool = false
var is_docked: bool = false
var dock_radius: float = 80.0

# Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO

const DASH_SPEED: float = 600.0
const DASH_DURATION: float = 0.2
const DASH_COOLDOWN: float = 1.0

# Collision layers for i-frames
var _original_collision_mask: int = 0

var owner_controller: Node = null
var current_dock: Node2D = null

@onready var left_laser: Laser = $LeftLaser
@onready var right_laser: Laser = $RightLaser
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var frame_sprite: Sprite2D = $Sprite2D
@onready var weapon_manager: WeaponManager = $WeaponManager

var lasers_enabled: bool = false
var starting_weapon := preload("res://resources/config/weapons/basic_gun.tres") as WeaponData

func _ready() -> void:
	add_to_group("player_ship")
	
	# Lasers always on for mining
	lasers_enabled = true
	_update_lasers()
	
	# Setup weapon manager
	if weapon_manager:
		weapon_manager.owner_ship = self
		# Add starting weapon
		if starting_weapon:
			weapon_manager.add_weapon(starting_weapon)
	
	# Apply stats from ship_stats resource
	if ship_stats:
		speed = ship_stats.base_speed
		
		var health_component := get_node_or_null("HealthComponent")
		if health_component:
			health_component.max_health = ship_stats.max_health
			health_component.current_health = ship_stats.max_health
		
		var speed_component := get_node_or_null("SpeedComponent")
		if speed_component:
			speed_component.base_speed = ship_stats.base_speed
		
		if left_laser:
			left_laser.color = ship_stats.laser_color
			left_laser.width = ship_stats.laser_width
			left_laser.direction = Vector2.UP  # Point forward
			left_laser.max_range = 30.0  # Short mining range
		if right_laser:
			right_laser.color = ship_stats.laser_color
			right_laser.width = ship_stats.laser_width
			right_laser.direction = Vector2.UP  # Point forward
			right_laser.max_range = 30.0  # Short mining range

func _physics_process(delta: float) -> void:
	if not is_active or not owner_controller:
		return
	
	# Handle Dash Cooldown
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	# Handle Dash State
	if is_dashing:
		dash_timer -= delta
		velocity = dash_velocity
		
		# Rotate towards mouse even while dashing
		var mouse_pos := get_global_mouse_position()
		look_at(mouse_pos)
		rotation += PI / 2.0
		
		move_and_slide()
		
		if dash_timer <= 0.0:
			_end_dash()
		return

	if is_docked:
		# Turret mode: No movement, but can rotate
		velocity = Vector2.ZERO
		
		# Rotate towards mouse/aim
		var mouse_pos := get_global_mouse_position()
		look_at(mouse_pos)
		rotation += PI / 2.0 # Adjust for sprite orientation
		return
	
	# Twin-Stick Rotation: Always look at mouse
	var mouse_pos := get_global_mouse_position()
	look_at(mouse_pos)
	rotation += PI / 2.0 # Adjust for sprite orientation
	
	# Handle movement (WASD)
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if not is_active or not owner_controller:
		return
	
	# Try to dock/undock (E key)
	if event.is_action_pressed("interact"):
		if is_docked:
			request_undock()
		else:
			try_dock()
			
	# Dash (Right Click)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_try_dash()
	
	# Note: Weapons auto-fire via WeaponManager, no manual firing needed

func try_dock() -> void:
	"""Request docking if near current dock"""
	if not current_dock or not owner_controller:
		return
	
	var dist := global_position.distance_to(current_dock.global_position)
	if dist > dock_radius:
		return
	
	if owner_controller.has_method("request_dock"):
		owner_controller.request_dock(self, current_dock)

# Weapon firing is now automatic via WeaponManager

func _update_lasers() -> void:
	"""Update laser visibility"""
	if left_laser:
		left_laser.set_is_casting(lasers_enabled)
	if right_laser:
		right_laser.set_is_casting(lasers_enabled)

func activate() -> void:
	is_active = true
	visible = true
	# Ensure lasers are on when ship activates
	lasers_enabled = true
	_update_lasers()

func deactivate() -> void:
	is_active = false
	# Turn off lasers when ship deactivates
	lasers_enabled = false
	_update_lasers()

func set_ship_id(id: int) -> void:
	ship_id = id

func set_owner_controller(controller: Node) -> void:
	owner_controller = controller

func set_current_dock(dock: Node2D) -> void:
	current_dock = dock

func set_docked(docked: bool) -> void:
	is_docked = docked
	if is_docked:
		velocity = Vector2.ZERO
		# Ensure lasers stay on
		lasers_enabled = true
		_update_lasers()

func request_undock() -> void:
	if not is_docked or not current_dock:
		return
	
	if current_dock.has_method("undock_ship"):
		current_dock.undock_ship(self)

func _try_dash() -> void:
	if is_dashing or dash_cooldown_timer > 0.0 or is_docked:
		return
	
	# Determine dash direction
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_dir == Vector2.ZERO:
		# Dash towards mouse if no movement input
		var mouse_pos := get_global_mouse_position()
		input_dir = (mouse_pos - global_position).normalized()
	else:
		input_dir = input_dir.normalized()
	
	_start_dash(input_dir)

func _start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_velocity = dir * DASH_SPEED
	
	# Enable I-Frames (disable collision with enemies/projectiles)
	_original_collision_mask = collision_mask
	collision_mask = 8 # Only collide with walls (layer 4 = 8)
	
	# Visual feedback (optional: modulate or particles)
	modulate.a = 0.5

func _end_dash() -> void:
	is_dashing = false
	dash_cooldown_timer = DASH_COOLDOWN
	velocity = Vector2.ZERO
	
	# Disable I-Frames
	collision_mask = _original_collision_mask
	
	# Reset visuals
	modulate.a = 1.0
