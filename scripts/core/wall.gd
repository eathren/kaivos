extends TileMapLayer

var trawler: Node2D

@export var wall_height_cells: int = 200
@export var nose_gap_tiles: int = 6
@export var tile_source_id: int = 0
@export var wall_atlas_coord: Vector2i = Vector2i(0, 0)
@export var ground_atlas_coord: Vector2i = Vector2i(0, 1)
@export var ground_thickness: int = 3

@export var fill_radius_world: float = 1000.0
@export var clear_radius_tiles: int = 5

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

	var clear_radius_sq: float = float(clear_radius_tiles * clear_radius_tiles)

	# wall only above trawler, leaving a nose gap and a clear bubble
	for x in range(left_x, right_x + 1):
		for y in range(top_y, trawler_cell.y - nose_gap_tiles + 1):
			var cell: Vector2i = Vector2i(x, y)
			var dx: float = float(cell.x - trawler_cell.x)
			var dy: float = float(cell.y - trawler_cell.y)
			if dx * dx + dy * dy <= clear_radius_sq:
				continue
			set_cell(cell, tile_source_id, wall_atlas_coord)
