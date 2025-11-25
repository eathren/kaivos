extends Node

var wall_tilemap: TileMapLayer

# Spawn preferences
@export var spawn_distance_behind_trawler: float = 500.0  # pixels behind trawler
@export var spawn_horizontal_spread: float = 200.0  # pixels to spread horizontally

func setup(walls: TileMapLayer) -> void:
	wall_tilemap = walls

## Get a spawn position behind the trawler, in open space
func get_spawn_position() -> Vector2:
	if wall_tilemap == null:
		push_warning("SpawnManager: Wall tilemap not set up")
		return Vector2.ZERO
	
	var trawler := get_tree().get_first_node_in_group("trawler") as Node2D
	if trawler == null:
		push_warning("SpawnManager: No trawler found")
		return Vector2.ZERO
	
	# Spawn behind the trawler (below in vertical shaft game)
	# Add some horizontal spread for variety
	var base_spawn_pos := trawler.global_position + Vector2(0, spawn_distance_behind_trawler)
	var horizontal_offset := randf_range(-spawn_horizontal_spread, spawn_horizontal_spread)
	var spawn_pos := base_spawn_pos + Vector2(horizontal_offset, 0)
	
	# Check if the spawn position is in a wall, and adjust if needed
	var spawn_local := wall_tilemap.to_local(spawn_pos)
	var spawn_cell := wall_tilemap.local_to_map(spawn_local)
	
	# Check if this cell is a wall
	var wall_atlas_coord := Vector2i(1, 1)
	var cell_atlas_coord := wall_tilemap.get_cell_atlas_coords(spawn_cell)
	var cell_source_id := wall_tilemap.get_cell_source_id(spawn_cell)
	
	# If it's a wall, try nearby positions
	if cell_source_id != -1 and cell_atlas_coord == wall_atlas_coord:
		# Try positions to the left and right
		for offset_x in [-2, -1, 1, 2, -3, 3]:
			var test_cell := spawn_cell + Vector2i(offset_x, 0)
			var test_atlas := wall_tilemap.get_cell_atlas_coords(test_cell)
			var test_source := wall_tilemap.get_cell_source_id(test_cell)
			
			if test_source == -1 or test_atlas != wall_atlas_coord:
				# Found a non-wall position
				var test_local := wall_tilemap.map_to_local(test_cell)
				spawn_pos = wall_tilemap.to_global(test_local)
				break
	
	return spawn_pos

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
	return inst
