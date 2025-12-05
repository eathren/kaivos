extends CharacterBody2D

## Base enemy script with component-based systems

@export var enemy_stats: EnemyStats = preload("res://resources/config/enemies/imp_tier1.tres")
@export var loot_table: LootTable = preload("res://resources/config/loot/basic_loot.tres")

var exp_crystal_scene: PackedScene = preload("res://entities/items/pickups/exp_crystal/exp_crystal.tscn")
var gold_pickup_scene: PackedScene = preload("res://entities/items/pickups/gold/gold_pickup.tscn")
var scrap_pickup_scene: PackedScene = preload("res://entities/items/pickups/scrap/scrap_pickup.tscn")

var _target: Node2D = null
var _health_component: HealthComponent = null
var _speed_component: SpeedComponent = null

# Level baked in at spawn time
var spawn_level: int = 1
var scaled_health: float = 0.0
var scaled_damage: float = 0.0
var is_elite: bool = false
var is_boss: bool = false

func _ready() -> void:
	add_to_group("enemy")
	
	# Get components
	_health_component = get_node_or_null("HealthComponent")
	_speed_component = get_node_or_null("SpeedComponent")
	
	# Apply stats from resource
	# Note: If spawner hasn't called apply_level() yet, we use base stats
	if enemy_stats:
		# Copy elite/boss status
		is_elite = enemy_stats.is_elite
		is_boss = enemy_stats.is_boss
		if scaled_health > 0:
			# Use pre-scaled stats from apply_level()
			if _health_component:
				_health_component.max_health = int(scaled_health)
				_health_component.current_health = _health_component.max_health
		else:
			# Fallback to base stats if no level applied
			if _health_component:
				_health_component.max_health = enemy_stats.max_health
				_health_component.current_health = enemy_stats.max_health
		
		if _speed_component:
			_speed_component.base_speed = enemy_stats.move_speed
	
	# Connect health component if it exists
	if _health_component:
		_health_component.died.connect(_on_death)
	
	# Find initial target (prefer player ship, fall back to trawler)
	_update_target()

func _physics_process(delta: float) -> void:
	# Update target if we don't have one
	if _target == null or not is_instance_valid(_target):
		_update_target()
	
	if _target == null:
		return
	
	# Move towards target
	var dir := (global_position.direction_to(_target.global_position))
	var current_speed := _speed_component.get_current_speed() if _speed_component else 60.0
	velocity = dir * current_speed
	move_and_slide()
	
	# Check for collision damage
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		
		# Damage player ship or trawler on collision
		if collider.is_in_group("player_ship") or collider.is_in_group("trawler"):
			_deal_damage_to(collider, delta)

func _update_target() -> void:
	# Prefer player ship as target
	var player_ships := get_tree().get_nodes_in_group("player_ship")
	if not player_ships.is_empty():
		_target = player_ships[0] as Node2D
		return
	
	# Fall back to trawler
	_target = get_tree().get_first_node_in_group("trawler") as Node2D

func _deal_damage_to(target: Node, delta: float) -> void:
	# Look for HealthComponent on target
	var health_comp = target.get_node_or_null("HealthComponent")
	if health_comp and health_comp.has_method("take_damage"):
		# Use baked damage from spawn level
		var dps := scaled_damage if scaled_damage > 0 else (enemy_stats.damage_per_second if enemy_stats else 10.0)
		health_comp.take_damage(dps * delta)

func _on_death(last_attacker_id: int = -1) -> void:
	# Increment kill counter
	if GameState:
		GameState.add_kill()
	
	# Award zeal to the killer
	if ZealManager:
		ZealManager.add_zeal(last_attacker_id)
	
	# Use loot table for drops
	if loot_table:
		_spawn_loot_from_table()
	else:
		# Fallback: spawn basic exp
		_spawn_exp_crystal()
	
	queue_free()

func _spawn_loot_from_table() -> void:
	"""Spawn loot based on loot table configuration"""
	if not loot_table:
		return
	
	# Always spawn EXP
	var exp_amount := randi_range(loot_table.exp_min, loot_table.exp_max)
	_spawn_exp_crystal(exp_amount)
	
	# Random chance for gold
	if randf() < loot_table.gold_drop_chance and gold_pickup_scene:
		var gold_amount := randi_range(loot_table.gold_amount_min, loot_table.gold_amount_max)
		var gold := gold_pickup_scene.instantiate() as Node2D
		if gold and "amount" in gold:
			gold.amount = gold_amount
			gold.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			get_parent().call_deferred("add_child", gold)
	
	# Random chance for scrap
	if randf() < loot_table.scrap_drop_chance and scrap_pickup_scene:
		var scrap_amount := randi_range(loot_table.scrap_amount_min, loot_table.scrap_amount_max)
		var scrap := scrap_pickup_scene.instantiate() as Node2D
		if scrap and "amount" in scrap:
			scrap.amount = scrap_amount
			scrap.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			get_parent().call_deferred("add_child", scrap)

func _spawn_exp_crystal(amount: int = 10) -> void:
	"""Spawn an exp crystal"""
	if not exp_crystal_scene:
		return
	
	var crystal := exp_crystal_scene.instantiate() as Node2D
	if crystal:
		if "xp_value" in crystal:
			crystal.xp_value = amount
		crystal.global_position = global_position
		get_parent().call_deferred("add_child", crystal)

func take_damage(amount: float) -> void:
	if _health_component:
		_health_component.take_damage(amount)
	else:
		# No health component, die immediately
		_on_death()

func apply_level(level: int) -> void:
	"""Called by spawner to bake in stats based on run difficulty"""
	spawn_level = level
	
	if not enemy_stats:
		return
	
	# Scale stats based on level (same formula as before, but baked in)
	# Health: +30% per level
	var hp_mult := 1.0 + 0.30 * float(level - 1)
	scaled_health = enemy_stats.max_health * hp_mult
	
	# Damage: +20% per level
	var dmg_mult := 1.0 + 0.20 * float(level - 1)
	scaled_damage = enemy_stats.damage_per_second * dmg_mult
	
	# Apply to components if they're already initialized
	if _health_component:
		_health_component.max_health = int(scaled_health)
		_health_component.current_health = _health_component.max_health
	
	# Update TouchDamageComponent if present
	var touch_damage = get_node_or_null("TouchDamageComponent")
	if touch_damage and touch_damage.has_method("set_scaled_damage"):
		# Use same damage scaling for touch damage
		var base_touch_damage = touch_damage.damage
		touch_damage.set_scaled_damage(int(base_touch_damage * dmg_mult))
