extends RefCounted
class_name MineGenerator

## Pure generation logic - works on data structures, not nodes
## Given a seed and config, outputs tile data and spawn positions
## Now uses WFC for terrain generation

const WfcHelper = preload("res://scripts/generation/wfc_helper.gd")

# Level configuration
var shaft_height_tiles: int = 3000
var shaft_width_tiles: int = 400  # Width on each side of trawler (800 total)
var starter_clearing_width_px: float = 500.0
var starter_clearing_height_px: float = 1000.0
var tile_size: float = 16.0
var chunk_size: int = 16  # Size of WFC chunks (reduced from 32 for faster generation)
var use_wfc: bool = true  # Enable WFC generation

# Generation result data
var wall_cells: Array[Vector2i] = []
var floor_cells: Array[Vector2i] = []
var ore_cells: Array[Vector2i] = []
var lava_cells: Array[Vector2i] = []
var feature_cells: Dictionary = {}  # symbol -> Array[Vector2i]
var trawler_start_cell: Vector2i = Vector2i.ZERO

# Debug visualization
var debug_view: Node = null

func _init(config: Dictionary = {}) -> void:
	if config.has("shaft_height_tiles"):
		shaft_height_tiles = config["shaft_height_tiles"]
	if config.has("shaft_width_tiles"):
		shaft_width_tiles = config["shaft_width_tiles"]
	if config.has("starter_clearing_width_px"):
		starter_clearing_width_px = config["starter_clearing_width_px"]
	if config.has("starter_clearing_height_px"):
		starter_clearing_height_px = config["starter_clearing_height_px"]

## Generate level data from seed
## Returns a dictionary with wall_cells array and trawler_start_cell
func build_level(level_seed: int, trawler_start_cell_pos: Vector2i = Vector2i.ZERO) -> Dictionary:
	wall_cells.clear()
	floor_cells.clear()
	ore_cells.clear()
	lava_cells.clear()
	feature_cells.clear()
	
	# Use level_seed for random generation
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level_seed)
	
	# If no trawler position provided, use origin
	if trawler_start_cell_pos == Vector2i.ZERO:
		trawler_start_cell = Vector2i(0, 0)
	else:
		trawler_start_cell = trawler_start_cell_pos
	
	# Convert pixel clearing to tiles
	var clearing_width_tiles: int = int(ceil(starter_clearing_width_px / tile_size))
	var clearing_height_tiles: int = int(ceil(starter_clearing_height_px / tile_size))
	
	# Calculate shaft boundaries
	var left_x: int = trawler_start_cell.x - shaft_width_tiles
	var right_x: int = trawler_start_cell.x + shaft_width_tiles
	var top_y: int = trawler_start_cell.y - shaft_height_tiles
	var bottom_y: int = trawler_start_cell.y + clearing_height_tiles
	
	# Calculate clearing boundaries (centered on trawler)
	var clearing_left_x: int = trawler_start_cell.x - (clearing_width_tiles / 2)
	var clearing_right_x: int = trawler_start_cell.x + (clearing_width_tiles / 2)
	var clearing_top_y: int = trawler_start_cell.y - clearing_height_tiles
	var clearing_bottom_y: int = trawler_start_cell.y
	
	if use_wfc:
		# Generate using WFC in chunks
		_generate_with_wfc(level_seed, left_x, right_x, top_y, bottom_y, clearing_left_x, clearing_right_x, clearing_top_y, clearing_bottom_y)
	else:
		# Fallback: Generate walls on left and right sides of shaft (around the clearing)
		for y in range(top_y, bottom_y + 1):
			# Left side of shaft (left of clearing)
			for x in range(left_x, clearing_left_x):
				wall_cells.append(Vector2i(x, y))
			
			# Right side of shaft (right of clearing)
			for x in range(clearing_right_x + 1, right_x + 1):
				wall_cells.append(Vector2i(x, y))
		
		# Generate walls above the clearing (top of shaft - solid wall)
		for y in range(top_y, clearing_top_y + 1):
			for x in range(left_x, right_x + 1):
				wall_cells.append(Vector2i(x, y))
	
	return {
		"wall_cells": wall_cells,
		"floor_cells": floor_cells,
		"ore_cells": ore_cells,
		"lava_cells": lava_cells,
		"feature_cells": feature_cells,
		"trawler_start_cell": trawler_start_cell,
		"clearing_bounds": {
			"left": clearing_left_x,
			"right": clearing_right_x,
			"top": clearing_top_y,
			"bottom": clearing_bottom_y
		}
	}

func _generate_with_wfc(
	level_seed: int,
	left_x: int, right_x: int,
	top_y: int, bottom_y: int,
	clearing_left_x: int, clearing_right_x: int,
	clearing_top_y: int, clearing_bottom_y: int
) -> void:
	"""Generate level using WFC in chunks"""
	
	# Calculate chunk grid bounds
	var chunk_left := int(floor(float(left_x) / chunk_size))
	var chunk_right := int(ceil(float(right_x) / chunk_size))
	var chunk_top := int(floor(float(top_y) / chunk_size))
	var chunk_bottom := int(ceil(float(bottom_y) / chunk_size))
	
	var total_chunks := (chunk_right - chunk_left + 1) * (chunk_bottom - chunk_top + 1)
	print("[WFC] Generating %d chunks from (%d, %d) to (%d, %d)" % [total_chunks, chunk_left, chunk_top, chunk_right, chunk_bottom])
	print("[WFC] World bounds: x=[%d to %d] y=[%d to %d]" % [left_x, right_x, top_y, bottom_y])
	print("[WFC] Clearing area: x=[%d to %d] y=[%d to %d]" % [clearing_left_x, clearing_right_x, clearing_top_y, clearing_bottom_y])
	
	# Initialize debug view if available
	if debug_view:
		debug_view.initialize_map(Vector2i(left_x, top_y), Vector2i(right_x, bottom_y))
		debug_view.update_chunk_progress(0, total_chunks)
	
	# Generate each chunk
	var chunks_generated := 0
	for cy in range(chunk_top, chunk_bottom + 1):
		for cx in range(chunk_left, chunk_right + 1):
			_generate_chunk(level_seed, cx, cy, clearing_left_x, clearing_right_x, clearing_top_y, clearing_bottom_y)
			chunks_generated += 1
			if chunks_generated % 10 == 0:
				print("[WFC] Progress: %d/%d chunks generated" % [chunks_generated, total_chunks])
			
			# Update debug view
			if debug_view:
				debug_view.update_chunk_progress(chunks_generated, total_chunks)
	
	print("[WFC] Generation complete: %d chunks" % total_chunks)
	
	# Highlight clearing area in debug view
	if debug_view:
		debug_view.highlight_clearing({
			"left": clearing_left_x,
			"right": clearing_right_x,
			"top": clearing_top_y,
			"bottom": clearing_bottom_y
		})

func _generate_chunk(
	level_seed: int,
	cx: int, cy: int,
	clearing_left_x: int, clearing_right_x: int,
	clearing_top_y: int, clearing_bottom_y: int
) -> void:
	"""Generate a single chunk using WFC"""
	
	# Get deterministic seed for this chunk
	var chunk_seed := WfcHelper.chunk_seed(str(level_seed), cx, cy)
	
	# Generate WFC symbols
	var symbol_grid := WfcHelper.generate_chunk(
		"res://data/wfc/mine_rules.json",
		chunk_size,
		chunk_seed
	)
	
	if symbol_grid.is_empty():
		print("[WFC ERROR] Generation failed for chunk (%d, %d)" % [cx, cy])
		return
	
	# Paint chunk to debug view
	if debug_view:
		debug_view.paint_chunk(Vector2i(cx, cy), symbol_grid)
	
	# Convert symbols to cell positions
	var chunk_origin := Vector2i(cx * chunk_size, cy * chunk_size)
	var symbol_counts := {}
	var cells_skipped := 0
	
	for y in range(chunk_size):
		for x in range(chunk_size):
			var cell_pos := Vector2i(chunk_origin.x + x, chunk_origin.y + y)
			
			# Skip if in clearing area
			if cell_pos.x >= clearing_left_x and cell_pos.x <= clearing_right_x and \
			   cell_pos.y >= clearing_top_y and cell_pos.y <= clearing_bottom_y:
				cells_skipped += 1
				continue
			
			var symbol: String = symbol_grid[y][x]
			
			# Track symbol distribution
			if symbol not in symbol_counts:
				symbol_counts[symbol] = 0
			symbol_counts[symbol] += 1
			
			# Map symbols to cell arrays
			match symbol:
				"WALL", "ROCK":
					wall_cells.append(cell_pos)
				"EMPTY", "CORRIDOR", "ROOM_FLOOR":
					floor_cells.append(cell_pos)
				"ORE":
					ore_cells.append(cell_pos)
				"LAVA":
					lava_cells.append(cell_pos)
				"DOOR", "TREASURE", "PILLAR":
					if symbol not in feature_cells:
						feature_cells[symbol] = []
					feature_cells[symbol].append(cell_pos)
	
	# Log chunk statistics (disabled for performance)
	# print("[WFC] Chunk (%d, %d) symbols: %s | Skipped: %d cells" % [cx, cy, symbol_counts, cells_skipped])
