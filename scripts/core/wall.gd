extends TileMapLayer

var trawler: Node2D

@export var wall_height_cells: int = 200
@export var nose_gap_tiles: int = 6
@export var tile_source_id: int = 5  # Wall tileset is at source 5 in the TileSet
@export var wall_atlas_coord: Vector2i = Vector2i(1, 1)  # Wall tile at (1, 1) in source 5
@export var ground_atlas_coord: Vector2i = Vector2i(0, 1)  # Ground is in source 2
@export var ground_thickness: int = 3

@export var fill_radius_world: float = 1000.0
@export var clear_radius_tiles: int = 5

var left_x: int
var right_x: int
var top_y: int

# Track damage per cell
var cell_damage: Dictionary = {}

func _ready() -> void:
	add_to_group("wall")
	
	# Level generation is now handled by LevelManager
	# This script only handles damage and cell management

func damage_cell(cell: Vector2i, damage: float) -> void:
	# Only damage wall tiles, not empty cells
	if get_cell_source_id(cell) == -1:
		return
	
	# Check both source ID and atlas coordinate to ensure it's a wall tile
	var cell_source_id := get_cell_source_id(cell)
	var atlas_coord := get_cell_atlas_coords(cell)
	if cell_source_id != tile_source_id or atlas_coord != wall_atlas_coord:
		return  # Don't damage ground tiles or tiles from other sources
	
	# Track damage for this cell
	var cell_key := "%d,%d" % [cell.x, cell.y]
	if not cell_damage.has(cell_key):
		cell_damage[cell_key] = 0.0
	
	cell_damage[cell_key] += damage
	
	# Remove cell if it takes enough damage (100 HP default)
	var max_health := 100.0
	if cell_damage[cell_key] >= max_health:
		erase_cell(cell)
		cell_damage.erase(cell_key)

# _generate_initial() removed - level generation is now handled by LevelManager
