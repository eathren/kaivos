extends TileMapLayer

var trawler: Node2D

@export var wall_height_cells: int = 200
@export var nose_gap_tiles: int = 6

@export var tile_source_id: int = 0
@export var wall_atlas_coord: Vector2i = Vector2i(0, 0)
@export var ground_atlas_coord: Vector2i = Vector2i(0, 1)
@export var ground_thickness: int = 3

var left_x: int
var right_x: int
var top_y: int

func _ready() -> void:
	await get_tree().process_frame

	trawler = get_tree().get_first_node_in_group("trawler")
	if trawler == null:
		push_error("WallGenerator: No trawler found in group 'trawler'")
		return

	_generate_initial()


func _generate_initial() -> void:
	var tile_size := tile_set.tile_size.x

	# desired width: ~1200 px, centered on trawler
	var target_width_px: float = 1200.0
	var half_screen_tiles := int(ceil((target_width_px * 0.5) / tile_size))
	var margin_tiles := 2

	var trawler_local := to_local(trawler.global_position)
	var trawler_cell := local_to_map(trawler_local)

	left_x = trawler_cell.x - half_screen_tiles - margin_tiles
	right_x = trawler_cell.x + half_screen_tiles + margin_tiles

	var first_wall_y := trawler_cell.y - nose_gap_tiles
	var last_wall_y := first_wall_y - wall_height_cells

	# fill wall (TileMapLayer version)
	for x in range(left_x, right_x + 1):
		for y in range(first_wall_y, last_wall_y - 1, -1):
			set_cell(Vector2i(x, y), tile_source_id, wall_atlas_coord)

	# ground under trawler
	for x in range(left_x, right_x + 1):
		for i in range(ground_thickness):
			var gy := trawler_cell.y + i
			set_cell(Vector2i(x, gy), tile_source_id, ground_atlas_coord)

	top_y = last_wall_y
