extends Node2D

## WFC Test Playground - Learn patterns from hand-painted SampleMap

@onready var sample_map: TileMapLayer = $SampleMap
@onready var target_map: TileMapLayer = $TargetMap
@onready var camera: Camera2D = $Camera2D

# Generation settings
@export var target_width: int = 200
@export var target_height: int = 200
@export var start_on_ready: bool = true

# Learned adjacency rules
var adjacency_rules: Dictionary = {}  # tile_id -> {N: [], E: [], S: [], W: []}
var tile_weights: Dictionary = {}  # tile_id -> weight (frequency)

func _ready() -> void:
	print("=== WFC Test Playground ===")
	print("Paint tiles in SampleMap (left side) to create training patterns")
	print("Press SPACE to generate from sample")
	print("Press R to clear target and regenerate")
	print("Press P to paint example pattern")
	
	# Center camera on target
	camera.position = Vector2(target_width * 8, target_height * 8)
	
	# Paint example if SampleMap is empty
	if sample_map.get_used_cells().is_empty():
		paint_example_pattern()
	
	if start_on_ready:
		generate_from_sample()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # SPACE
		generate_from_sample()
	elif event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		target_map.clear()
		generate_from_sample()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_P:
		sample_map.clear()
		paint_example_pattern()
		print("[WFC] Example pattern painted! Press SPACE to generate.")

func generate_from_sample() -> void:
	print("\n[WFC] Starting generation...")
	var start_time = Time.get_ticks_msec()
	
	# Step 1: Learn patterns from SampleMap
	learn_adjacency_from_sample()
	
	if adjacency_rules.is_empty():
		push_error("[WFC] No patterns learned! Paint some tiles in SampleMap first.")
		return
	
	print("[WFC] Learned %d tile patterns" % adjacency_rules.size())
	
	# Step 2: Generate TargetMap using learned rules
	generate_target_map()
	
	var elapsed = Time.get_ticks_msec() - start_time
	print("[WFC] Generation complete in %d ms" % elapsed)

func learn_adjacency_from_sample() -> void:
	"""Scan SampleMap and learn which tiles can be adjacent to each other"""
	adjacency_rules.clear()
	tile_weights.clear()
	
	# Get bounds of painted tiles
	var used_cells = sample_map.get_used_cells()
	if used_cells.is_empty():
		return
	
	print("[WFC] Scanning %d sample tiles..." % used_cells.size())
	
	# For each tile, record what tiles appear in each direction
	for cell in used_cells:
		var tile_data = sample_map.get_cell_tile_data(cell)
		if not tile_data:
			continue
		
		var atlas_coords = sample_map.get_cell_atlas_coords(cell)
		var tile_id = _coord_to_id(atlas_coords)
		
		# Count frequency for weights
		if not tile_weights.has(tile_id):
			tile_weights[tile_id] = 0
		tile_weights[tile_id] += 1
		
		# Initialize adjacency if needed
		if not adjacency_rules.has(tile_id):
			adjacency_rules[tile_id] = {
				"N": [],
				"E": [],
				"S": [],
				"W": []
			}
		
		# Check each direction
		var directions = {
			"N": Vector2i(0, -1),
			"E": Vector2i(1, 0),
			"S": Vector2i(0, 1),
			"W": Vector2i(-1, 0)
		}
		
		for dir_name in directions:
			var neighbor_cell = cell + directions[dir_name]
			var neighbor_coords = sample_map.get_cell_atlas_coords(neighbor_cell)
			
			if neighbor_coords != Vector2i(-1, -1):  # Tile exists
				var neighbor_id = _coord_to_id(neighbor_coords)
				
				# Add to allowed neighbors if not already there
				if neighbor_id not in adjacency_rules[tile_id][dir_name]:
					adjacency_rules[tile_id][dir_name].append(neighbor_id)
	
	print("[WFC] Learned rules for %d unique tiles" % adjacency_rules.size())

func generate_target_map() -> void:
	"""Generate target using simple WFC-inspired algorithm"""
	target_map.clear()
	
	# Start with a random tile in the center
	var all_tiles = adjacency_rules.keys()
	if all_tiles.is_empty():
		return
	
	var start_tile = all_tiles[randi() % all_tiles.size()]
	var start_pos = Vector2i(target_width / 2, target_height / 2)
	
	_place_tile(start_pos, start_tile)
	
	# Expand outward using a simple frontier approach
	var frontier: Array[Vector2i] = [start_pos]
	var placed: Dictionary = {start_pos: true}
	var max_iterations = target_width * target_height * 2
	var iterations = 0
	
	while not frontier.is_empty() and iterations < max_iterations:
		iterations += 1
		
		# Pick random frontier cell
		var current = frontier[randi() % frontier.size()]
		frontier.erase(current)
		
		# Try to place tiles in all 4 directions
		var directions = {
			"N": Vector2i(0, -1),
			"E": Vector2i(1, 0),
			"S": Vector2i(0, 1),
			"W": Vector2i(-1, 0)
		}
		
		for dir_name in directions:
			var next_pos = current + directions[dir_name]
			
			# Skip if out of bounds or already placed
			if next_pos.x < 0 or next_pos.x >= target_width:
				continue
			if next_pos.y < 0 or next_pos.y >= target_height:
				continue
			if placed.has(next_pos):
				continue
			
			# Find valid tile for this position
			var valid_tile = _find_valid_tile(next_pos, placed)
			if valid_tile != null:
				_place_tile(next_pos, valid_tile)
				placed[next_pos] = true
				frontier.append(next_pos)
	
	print("[WFC] Placed %d tiles (iterations: %d)" % [placed.size(), iterations])

func _find_valid_tile(pos: Vector2i, placed: Dictionary) -> Variant:
	"""Find a tile that satisfies constraints from neighbors"""
	var candidates = adjacency_rules.keys().duplicate()
	
	# Check each direction for constraints
	var directions = {
		"N": [Vector2i(0, -1), "S"],  # If tile above, we need to match its S
		"E": [Vector2i(1, 0), "W"],
		"S": [Vector2i(0, 1), "N"],
		"W": [Vector2i(-1, 0), "E"]
	}
	
	for dir_name in directions:
		var offset = directions[dir_name][0]
		var opposite = directions[dir_name][1]
		var neighbor_pos = pos + offset
		
		if placed.has(neighbor_pos):
			# Get the tile at neighbor
			var neighbor_coords = target_map.get_cell_atlas_coords(neighbor_pos)
			var neighbor_id = _coord_to_id(neighbor_coords)
			
			if adjacency_rules.has(neighbor_id):
				var allowed = adjacency_rules[neighbor_id][opposite]
				
				# Filter candidates to only those allowed by this neighbor
				var new_candidates = []
				for tile_id in candidates:
					if tile_id in allowed:
						new_candidates.append(tile_id)
				candidates = new_candidates
				
				if candidates.is_empty():
					return null  # Contradiction
	
	# Pick weighted random from candidates
	if candidates.is_empty():
		# Fallback to any tile
		return adjacency_rules.keys()[randi() % adjacency_rules.size()]
	
	# Weight by frequency in sample
	var total_weight = 0.0
	for tile_id in candidates:
		total_weight += tile_weights.get(tile_id, 1.0)
	
	var rand_val = randf() * total_weight
	var accumulated = 0.0
	
	for tile_id in candidates:
		accumulated += tile_weights.get(tile_id, 1.0)
		if rand_val <= accumulated:
			return tile_id
	
	return candidates[0]

func _place_tile(pos: Vector2i, tile_id: int) -> void:
	"""Place a tile at position"""
	var coords = _id_to_coord(tile_id)
	target_map.set_cell(pos, 6, coords)  # source_id = 6

func _coord_to_id(coords: Vector2i) -> int:
	"""Convert atlas coords to unique ID"""
	return coords.y * 100 + coords.x

func _id_to_coord(tile_id: int) -> Vector2i:
	"""Convert unique ID back to atlas coords"""
	return Vector2i(tile_id % 100, tile_id / 100)

func paint_example_pattern() -> void:
	"""Paint an example mine pattern with rooms, corridors, and ore"""
	sample_map.clear()
	
	# Using source_id = 6 for wfc_tileset
	var source = 6
	var wall = Vector2i(1, 1)    # Wall center
	var floor = Vector2i(1, 5)   # Ground floor
	var ore = Vector2i(0, 6)     # Ore
	var lava = Vector2i(3, 6)    # Lava
	
	# Create a sample 64x48 area showing various patterns
	var width = 64
	var height = 48
	
	# Fill with rock walls as base
	for y in range(height):
		for x in range(width):
			sample_map.set_cell(Vector2i(x, y), source, wall)
	
	# Room 1: Large rectangular room (top-left)
	_carve_room(4, 4, 16, 10, source, floor)
	# Add some ore deposits in room
	sample_map.set_cell(Vector2i(8, 8), source, ore)
	sample_map.set_cell(Vector2i(15, 12), source, ore)
	
	# Room 2: Smaller room (top-right)
	_carve_room(40, 4, 12, 8, source, floor)
	sample_map.set_cell(Vector2i(44, 7), source, ore)
	
	# Room 3: Irregular room (bottom-left)
	_carve_room(6, 30, 14, 12, source, floor)
	# Lava pool in corner
	sample_map.set_cell(Vector2i(8, 38), source, lava)
	sample_map.set_cell(Vector2i(9, 38), source, lava)
	
	# Room 4: Treasure room (bottom-right)
	_carve_room(38, 32, 10, 10, source, floor)
	# Surrounded by ore
	sample_map.set_cell(Vector2i(42, 36), source, ore)
	sample_map.set_cell(Vector2i(43, 36), source, ore)
	
	# Horizontal corridor connecting top rooms
	_carve_corridor(20, 8, 40, 8, source, floor)
	
	# Vertical corridor down from room 1
	_carve_corridor(12, 14, 12, 30, source, floor)
	
	# L-shaped corridor to bottom-right room
	_carve_corridor(12, 36, 38, 36, source, floor)
	
	# Add some ore veins in walls near corridors
	sample_map.set_cell(Vector2i(25, 7), source, ore)
	sample_map.set_cell(Vector2i(11, 20), source, ore)
	sample_map.set_cell(Vector2i(13, 20), source, ore)
	
	# Natural cave opening (top middle)
	_carve_organic_cave(28, 4, 8, source, floor, ore)
	
	print("[WFC] Painted example: 4 rooms, 3 corridors, ore veins, 1 lava pool")

func _carve_room(x: int, y: int, w: int, h: int, source: int, floor_tile: Vector2i) -> void:
	"""Carve out a rectangular room"""
	for ry in range(y, y + h):
		for rx in range(x, x + w):
			sample_map.set_cell(Vector2i(rx, ry), source, floor_tile)

func _carve_corridor(x1: int, y1: int, x2: int, y2: int, source: int, floor_tile: Vector2i) -> void:
	"""Carve a straight corridor between two points"""
	if x1 == x2:  # Vertical
		var start = mini(y1, y2)
		var end = maxi(y1, y2)
		for y in range(start, end + 1):
			sample_map.set_cell(Vector2i(x1, y), source, floor_tile)
			# Make it 2 tiles wide
			sample_map.set_cell(Vector2i(x1 + 1, y), source, floor_tile)
	else:  # Horizontal
		var start = mini(x1, x2)
		var end = maxi(x1, x2)
		for x in range(start, end + 1):
			sample_map.set_cell(Vector2i(x, y1), source, floor_tile)
			# Make it 2 tiles wide
			sample_map.set_cell(Vector2i(x, y1 + 1), source, floor_tile)

func _carve_organic_cave(cx: int, cy: int, radius: int, source: int, floor_tile: Vector2i, ore_tile: Vector2i) -> void:
	"""Carve an organic-looking cave area"""
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var dist = sqrt(dx * dx + dy * dy)
			if dist < radius:
				var pos = Vector2i(cx + dx, cy + dy)
				# 70% floor, 30% ore for organic look
				if randf() < 0.7:
					sample_map.set_cell(pos, source, floor_tile)
				else:
					sample_map.set_cell(pos, source, ore_tile)
