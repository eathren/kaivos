extends CharacterBody2D

@export var crew_stats: CrewStats = preload("res://resources/config/crew/default_crew.tres")

var speed: float = 200.0  # Set from crew_stats in _ready()
var is_active: bool = true
var health_bar: ProgressBar = null

func _ready() -> void:
	add_to_group("player")
	
	# Connect to hurtbox component signals
	var hurtbox = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	
	# Apply stats from crew_stats resource
	if crew_stats:
		speed = crew_stats.move_speed
		
		# Apply to HealthComponent (scaled by team level)
		var health_component := get_node_or_null("HealthComponent") as HealthComponent
		if health_component:
			health_component.max_health = GameState.get_base_max_health()
			health_component.current_health = health_component.max_health
		
		# Apply to SpeedComponent
		var speed_component := get_node_or_null("SpeedComponent") as SpeedComponent
		if speed_component:
			speed_component.base_speed = crew_stats.move_speed
		
		# Apply to HealthRegenComponent (scaled by team level)
		var health_regen := get_node_or_null("HealthRegenComponent") as HealthRegenComponent
		if health_regen:
			health_regen.base_regen_per_second = GameState.get_base_health_regen()
			health_regen.current_regen_rate = GameState.get_base_health_regen()
		
		# Apply pickup range to PickupArea
		var pickup_area := get_node_or_null("PickupArea") as Area2D
		if pickup_area:
			var collision_shape := pickup_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if collision_shape and collision_shape.shape is CircleShape2D:
				var circle := collision_shape.shape as CircleShape2D
				circle.radius = crew_stats.pickup_range * GameState.get_pickup_range_multiplier()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	# Only process input for local authority
	if not is_multiplayer_authority():
		return
	
	var input_dir := Vector2.ZERO

	# Use your own input actions, not ui_left/right/up/down
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func deactivate() -> void:
	is_active = false
	visible = false
	set_physics_process(false)

func activate() -> void:
	is_active = true
	visible = true
	set_physics_process(true)

func _on_hit_received(damage: int, attacker: Node) -> void:
	"""Called when HurtboxComponent receives damage"""
	# Show/update health bar
	if not health_bar:
		_spawn_health_bar()
	
	if health_bar:
		var health_component = get_node_or_null("HealthComponent") as HealthComponent
		if health_component:
			health_bar.max_value = health_component.max_health
			health_bar.value = health_component.current_health
			health_bar.visible = true

func take_damage(amount: int) -> void:
	"""Deprecated - damage is now handled by HurtboxComponent"""
	pass
	

func _spawn_health_bar() -> void:
	"""Create floating health bar above player"""
	if health_bar:
		return
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(40, 6)
	health_bar.position = Vector2(-20, -20)
	health_bar.show_percentage = false
	
	# Style the health bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	health_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	health_bar.add_theme_stylebox_override("fill", style_fill)
	
	add_child(health_bar)
