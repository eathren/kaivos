extends Node

## Level Manager - Handles level generation, progression, and save/load
## Manages the vertical shaft generation and level state

signal level_generated
signal level_progress_updated(progress: float)  # 0.0 to 1.0

# Level configuration
@export var shaft_height_tiles: int = 3000  # Total height of the shaft
@export var shaft_width_tiles: int = 400  # Width on each side of trawler (800 total)
@export var starter_clearing_width_px: float = 500.0  # Starter clearing width in pixels
@export var starter_clearing_height_px: float = 1000.0  # Starter clearing height in pixels
@export var level_duration_minutes: float = 10.0  # 10 minute levels

# Level state
var current_level: int = 1
var level_start_time: float = 0.0
var trawler_start_position: Vector2 = Vector2.ZERO
var wall_tilemap: TileMapLayer = null

# Save/load keys
const SAVE_KEY_LEVEL: String = "current_level"
const SAVE_KEY_START_TIME: String = "level_start_time"
const SAVE_KEY_START_POS: String = "trawler_start_position"

func _ready() -> void:
	# Connect to GameState for save/load
	pass

## Initialize a new level
func start_level(level_num: int = 1, trawler_pos: Vector2 = Vector2.ZERO) -> void:
	current_level = level_num
	level_start_time = Time.get_ticks_msec() / 1000.0
	trawler_start_position = trawler_pos
	
	# Find wall tilemap
	wall_tilemap = get_tree().get_first_node_in_group("wall") as TileMapLayer
	if wall_tilemap == null:
		push_error("LevelManager: No wall TileMapLayer found in group 'wall'")
		return
	
	# Generate the level
	_generate_level()
	
	level_generated.emit()

## Generate the vertical shaft level
func _generate_level() -> void:
	if wall_tilemap == null:
		push_error("LevelManager: Cannot generate level - no wall tilemap")
		return
	
	# Convert pixel clearing to tiles (assuming 16x16 tiles)
	var tile_size: float = 16.0
	var clearing_width_tiles: int = int(ceil(starter_clearing_width_px / tile_size))
	var clearing_height_tiles: int = int(ceil(starter_clearing_height_px / tile_size))
	
	# Get trawler position in tilemap coordinates
	var trawler_local := wall_tilemap.to_local(trawler_start_position)
	var trawler_cell := wall_tilemap.local_to_map(trawler_local)
	
	# Calculate shaft boundaries
	var left_x: int = trawler_cell.x - shaft_width_tiles
	var right_x: int = trawler_cell.x + shaft_width_tiles
	var top_y: int = trawler_cell.y - shaft_height_tiles
	var bottom_y: int = trawler_cell.y + clearing_height_tiles  # Extend below for starter clearing
	
	# Get wall generation parameters from wall script
	# Access exported properties directly from the TileMapLayer script
	var tile_source_id: int = 5  # Default from wall.gd
	var wall_atlas_coord: Vector2i = Vector2i(1, 1)  # Default from wall.gd
	
	# Try to get exported values from wall script instance
	if "tile_source_id" in wall_tilemap:
		tile_source_id = wall_tilemap.get("tile_source_id")
	if "wall_atlas_coord" in wall_tilemap:
		wall_atlas_coord = wall_tilemap.get("wall_atlas_coord")
	
	# Calculate clearing boundaries (centered on trawler)
	var clearing_left_x: int = trawler_cell.x - (clearing_width_tiles / 2)
	var clearing_right_x: int = trawler_cell.x + (clearing_width_tiles / 2)
	var clearing_top_y: int = trawler_cell.y - clearing_height_tiles
	var clearing_bottom_y: int = trawler_cell.y
	
	# Generate walls on left and right sides of shaft (around the clearing)
	# Left wall (from top to bottom, excluding clearing area)
	for y in range(top_y, bottom_y + 1):
		# Left side of shaft (left of clearing)
		for x in range(left_x, clearing_left_x):
			var cell := Vector2i(x, y)
			wall_tilemap.set_cell(cell, tile_source_id, wall_atlas_coord)
		
		# Right side of shaft (right of clearing)
		for x in range(clearing_right_x + 1, right_x + 1):
			var cell := Vector2i(x, y)
			wall_tilemap.set_cell(cell, tile_source_id, wall_atlas_coord)
	
	# Generate walls above the clearing (top of shaft - solid wall)
	for y in range(top_y, clearing_top_y + 1):
		for x in range(left_x, right_x + 1):
			var cell := Vector2i(x, y)
			wall_tilemap.set_cell(cell, tile_source_id, wall_atlas_coord)
	
	print("LevelManager: Generated level %d - Shaft: %d tiles tall, %d tiles wide each side" % [current_level, shaft_height_tiles, shaft_width_tiles])
	print("LevelManager: Starter clearing: %d x %d tiles at trawler position" % [clearing_width_tiles, clearing_height_tiles])

## Get level progress (0.0 to 1.0)
func get_level_progress() -> float:
	if level_duration_minutes <= 0.0:
		return 0.0
	
	var elapsed_seconds: float = (Time.get_ticks_msec() / 1000.0) - level_start_time
	var elapsed_minutes: float = elapsed_seconds / 60.0
	var progress: float = clamp(elapsed_minutes / level_duration_minutes, 0.0, 1.0)
	
	level_progress_updated.emit(progress)
	return progress

## Check if level is complete
func is_level_complete() -> bool:
	return get_level_progress() >= 1.0

## Save level state to GameState
func save_level_state() -> void:
	if GameState == null:
		push_warning("LevelManager: GameState not available for saving")
		return
	
	# Level state is saved through GameState.save_game()
	# This method is kept for API consistency
	GameState.save_game()

## Load level state from GameState
func load_level_state() -> bool:
	if GameState == null:
		push_warning("LevelManager: GameState not available for loading")
		return false
	
	# Load game state (which includes level state)
	return GameState.load_game()

## Reset level (for restart/new game)
func reset_level() -> void:
	current_level = 1
	level_start_time = 0.0
	trawler_start_position = Vector2.ZERO
