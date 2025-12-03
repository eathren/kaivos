extends CharacterBody2D

@export var crew_stats: CrewStats = preload("res://resources/config/crew/default_crew.tres")

var speed: float = 200.0  # Set from crew_stats in _ready()
var is_active: bool = true
var health_bar: ProgressBar = null
var invulnerable: bool = false
var invulnerable_timer: float = 0.0
const INVULNERABLE_TIME: float = 0.5  # Half second of invulnerability after hit

func _ready() -> void:
	add_to_group("player")
	
	# Connect hurt box
	var hurt_box = get_node_or_null("HurtBox") as Area2D
	if hurt_box:
		hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	
	# Apply stats from crew_stats resource
	if crew_stats:
		speed = crew_stats.move_speed
		
		# Apply to HealthComponent
		var health_component := get_node_or_null("HealthComponent") as HealthComponent
		if health_component:
			health_component.max_health = crew_stats.max_health
			health_component.current_health = crew_stats.max_health
		
		# Apply to SpeedComponent
		var speed_component := get_node_or_null("SpeedComponent") as SpeedComponent
		if speed_component:
			speed_component.base_speed = crew_stats.move_speed
		
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
	
	# Update invulnerability timer
	if invulnerable:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0:
			invulnerable = false
			modulate = Color.WHITE
		
		# Flash effect during invulnerability
		if int(invulnerable_timer * 10) % 2 == 0:
			modulate = Color(1, 1, 1, 0.5)
		else:
			modulate = Color.WHITE
	
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

func _on_hurt_box_area_entered(area: Area2D) -> void:
	"""Handle damage from enemy damage areas"""
	if invulnerable:
		return
	
	# Check if it's an enemy damage area
	var enemy = area.get_parent()
	var damage_component = enemy.get_node_or_null("TouchDamageComponent")
	if damage_component and damage_component.has_method("can_damage_target"):
		if damage_component.can_damage_target(self):
			var damage = damage_component.get_damage()
			damage_component.record_damage(self)
			take_damage(damage)

func take_damage(amount: int) -> void:
	"""Take damage and update health bar"""
	if invulnerable:
		return
	
	var health_component = get_node_or_null("HealthComponent") as HealthComponent
	if health_component:
		health_component.take_damage(amount)
		
		# Show health bar if not visible
		if not health_bar:
			_spawn_health_bar()
		
		# Update health bar
		if health_bar:
			health_bar.max_value = health_component.max_health
			health_bar.value = health_component.current_health
			health_bar.visible = true
		
		# Start invulnerability
		invulnerable = true
		invulnerable_timer = INVULNERABLE_TIME
		
		print("Player took %d damage! Health: %d/%d" % [amount, health_component.current_health, health_component.max_health])

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
