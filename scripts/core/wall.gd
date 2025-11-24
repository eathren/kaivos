extends TileMapLayer

var trawler: Node2D

@export var wall_height_cells: int = 200          # not really used now, keep if you want later
@export var nose_gap_tiles: int = 6               # same
@export var tile_source_id: int = 0
@export var wall_atlas_coord: Vector2i = Vector2i(0, 0)
@export var ground_atlas_coord: Vector2i = Vector2i(0, 1)
@export var ground_thickness: int = 3

# New: radius in world units (pixels) to fill around the trawler
@export var fill_radius_world: float = 1000.0

var left_x: int
var right_x: int
var top_y: int

func _ready() -> void:
	await get_tree().process_frame

	trawler = get_tree().get_first_node_in_group("trawler") as Node2D
	if trawler == null:
		push_error("WallGenerator: No trawler found in group 'trawler'")
		return

	_generate_initial()

func _generate_initial() -> void:
	if trawler == null:
		return

	var tile_size: float = float(tile_set.tile_size.x)
	var radius_tiles: int = int(ceil(fill_radius_world / tile_size))

	var trawler_local: Vector2 = to_local(trawler.global_position)
	var trawler_cell: Vector2i = local_to_map(trawler_local)

	left_x = trawler_cell.x - radius_tiles
	right_x = trawler_cell.x + radius_tiles

	top_y = trawler_cell.y - radius_tiles
	var bottom_y: int = trawler_cell.y + radius_tiles

	# Fill walls in a square around the trawler
	for x in range(left_x, right_x + 1):
		for y in range(top_y, bottom_y + 1):
			set_cell(Vector2i(x, y), tile_source_id, wall_atlas_coord)
