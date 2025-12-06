extends Node

var wall_tilemap: TileMapLayer

# Spawn preferences
@export var min_spawn_distance: float = 650.0  # Minimum distance (off-screen)
@export var max_spawn_distance: float = 1000.0 # Maximum distance (relevant)




var _map_min_x: float = -100000.0
var _map_max_x: float = 100000.0

func setup(walls: TileMapLayer) -> void:
	wall_tilemap = walls

func set_bounds(min_x: float, max_x: float) -> void:
	_map_min_x = min_x
	_map_max_x = max_x
	print("SpawnManager: Bounds set to x=%.1f to %.1f" % [_map_min_x, _map_max_x])



## Get a spawn position in a donut shape around targets
func get_spawn_position() -> Vector2:
	if wall_tilemap == null:
		return Vector2.ZERO
	
	# Collect valid targets (Trawler + Players)
	var targets: Array[Node2D] = []
	var trawler := get_tree().get_first_node_in_group("trawler") as Node2D
	if trawler:
		targets.append(trawler)
	
	var players := get_tree().get_nodes_in_group("player_ship")
	for p in players:
		if p is Node2D:
			targets.append(p)
	
	if targets.is_empty():
		return Vector2.ZERO
	
	# Try to find a valid position
	for i in range(10):
		# 1. Pick random target
		var target = targets.pick_random()
		
		# 2. Pick random angle and distance
		var angle := randf() * TAU
		var dist := randf_range(min_spawn_distance, max_spawn_distance)
		var offset := Vector2.RIGHT.rotated(angle) * dist
		
		var candidate_pos = target.global_position + offset
		
		# 3. Clamp to map bounds (with margin)
		var margin := 32.0
		candidate_pos.x = clamp(candidate_pos.x, _map_min_x + margin, _map_max_x - margin)
		
		# 4. Check if valid floor
		if _is_valid_spawn_pos(candidate_pos):
			return candidate_pos
			
	return Vector2.ZERO

func _is_valid_spawn_pos(global_pos: Vector2) -> bool:
	var local_pos := wall_tilemap.to_local(global_pos)
	var cell := wall_tilemap.local_to_map(local_pos)
	
	# Check if it's a wall (source_id != -1 means there is a tile on the wall layer)
	# In this game, Wall layer contains Walls AND Ores.
	# We want to spawn where there is NO wall tile (empty space on Wall layer)
	# OR where there is a Floor tile on the Ground layer (if we had reference to it)
	# But level_mine.gd says: "Place floor tiles EVERYWHERE... Place wall tiles on Wall layer"
	# So if Wall layer has no tile, it's floor.
	
	# Check a 3x3 area to ensure the enemy (approx 32x32) fits
	# This prevents spawning partially inside a wall
	for y in range(-1, 2):
		for x in range(-1, 2):
			var check_cell = cell + Vector2i(x, y)
			var source_id := wall_tilemap.get_cell_source_id(check_cell)
			if source_id != -1:
				return false # Found a wall in the 3x3 area
				
	return true
		
	return false

## Spawn an enemy at a valid position behind the trawler
func spawn(scene: PackedScene, parent: Node = null) -> Node2D:
	var pos := get_spawn_position()
	if pos == Vector2.ZERO:
		return null
	
	var inst := scene.instantiate() as Node2D
	if inst == null:
		return null

	if parent == null:
		parent = get_tree().current_scene

	parent.add_child(inst)
	inst.global_position = pos
	
	# Apply run difficulty level to enemy
	if RunManager and RunManager.difficulty and inst.has_method("apply_level"):
		var level := RunManager.difficulty.get_enemy_level()
		inst.apply_level(level)
	
	return inst
