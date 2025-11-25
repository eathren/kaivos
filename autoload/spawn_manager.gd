extends Node

var wall_tilemap: TileMapLayer

var _spawn_cells: Array[Vector2i] = []
var _wall_cells: Dictionary = {}

# Spawn preferences
@export var prefer_wall_edges: bool = false
@export var min_distance_from_player: float =  50.0  # pixels
@export var spawn_radius_tiles: int = 50  # How far from trawler to search for spawn cells


func setup(walls: TileMapLayer) -> void:
	wall_tilemap = walls
	_rebuild_spawn_cells()


func _rebuild_spawn_cells() -> void:
	_spawn_cells.clear()
	_wall_cells.clear()
	
	if wall_tilemap == null:
		push_error("SpawnManager.setup was not called correctly")
		return

	# Build a fast lookup of wall cells by checking atlas coordinates
	# Wall tiles are at (1, 1), ground/other tiles are at different coords
	var wall_atlas_coord := Vector2i(1, 1)  # Based on wall.gd
	
	for cell in wall_tilemap.get_used_cells():
		var atlas_coord := wall_tilemap.get_cell_atlas_coords(cell)
		if atlas_coord == wall_atlas_coord:
			_wall_cells[cell] = true

	# Find all valid spawn cells - anywhere that isn't a wall
	# We'll search in a radius around the trawler for efficiency
	var trawler := get_tree().get_first_node_in_group("trawler") as Node2D
	if trawler == null:
		push_warning("SpawnManager: No trawler found, cannot determine spawn area")
		return
	
	var trawler_local := wall_tilemap.to_local(trawler.global_position)
	var trawler_cell := wall_tilemap.local_to_map(trawler_local)
	
	# Search in a large radius around trawler
	var wall_edge_cells: Array[Vector2i] = []
	var open_cells: Array[Vector2i] = []
	
	for x in range(trawler_cell.x - spawn_radius_tiles, trawler_cell.x + spawn_radius_tiles + 1):
		for y in range(trawler_cell.y - spawn_radius_tiles, trawler_cell.y + spawn_radius_tiles + 1):
			var cell := Vector2i(x, y)
			
			# Skip if it's a wall cell
			if _wall_cells.has(cell):
				continue
			
			# Check if cell exists in tilemap (has any tile) or is empty
			# Empty cells are also valid spawn points
			var source_id := wall_tilemap.get_cell_source_id(cell)
			if source_id == -1 or not _wall_cells.has(cell):
				# Valid spawn location - check if it's adjacent to a wall
				if prefer_wall_edges and _is_adjacent_to_wall(cell):
					wall_edge_cells.append(cell)
				else:
					open_cells.append(cell)
	
	# Combine spawn cells, prioritizing wall edges
	if prefer_wall_edges:
		_spawn_cells.append_array(wall_edge_cells)
	_spawn_cells.append_array(open_cells)
	
	# Remove duplicates
	var unique_cells := {}
	for cell in _spawn_cells:
		unique_cells[cell] = true
	_spawn_cells = unique_cells.keys()
	
	print("SpawnManager: Found %d valid spawn cells (%d wall edges, %d open)" % [_spawn_cells.size(), wall_edge_cells.size(), open_cells.size()])


func _is_adjacent_to_wall(cell: Vector2i) -> bool:
	# Check if this cell is adjacent to at least one wall cell
	var neighbors := [
		Vector2i(cell.x + 1, cell.y),  # Right
		Vector2i(cell.x - 1, cell.y),  # Left
		Vector2i(cell.x, cell.y + 1),  # Down
		Vector2i(cell.x, cell.y - 1),   # Up
	]
	
	for neighbor in neighbors:
		if _wall_cells.has(neighbor):
			return true
	
	return false




func get_spawn_position() -> Vector2:
	if _spawn_cells.is_empty():
		push_warning("SpawnManager has no spawn cells")
		return Vector2.ZERO

	# Try to find a position away from player
	var trawler := get_tree().get_first_node_in_group("trawler") as Node2D
	var attempts := 0
	var max_attempts := 20
	
	while attempts < max_attempts:
		var idx := randi() % _spawn_cells.size()
		var cell: Vector2i = _spawn_cells[idx]
		
		# Tile coords -> global coordinates
		var local_pos := wall_tilemap.map_to_local(cell)
		var global_pos := wall_tilemap.to_global(local_pos)
		
		# Check distance from player if specified
		if trawler != null and min_distance_from_player > 0.0:
			var distance := global_pos.distance_to(trawler.global_position)
			if distance >= min_distance_from_player:
				return global_pos
		else:
			# No distance requirement, return immediately
			return global_pos
		
		attempts += 1
	
	# Fallback: return random position even if too close
	var idx := randi() % _spawn_cells.size()
	var cell: Vector2i = _spawn_cells[idx]
	var local_pos := wall_tilemap.map_to_local(cell)
	return wall_tilemap.to_global(local_pos)


func spawn(scene: PackedScene, parent: Node = null) -> Node2D:
	var pos := get_spawn_position()
	var inst := scene.instantiate() as Node2D

	if parent == null:
		parent = get_tree().current_scene

	parent.add_child(inst)
	inst.global_position = pos
	return inst


# Call this when walls are destroyed/updated to refresh spawn cells
func refresh_spawn_cells() -> void:
	_rebuild_spawn_cells()
