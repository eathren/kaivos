extends Node2D

@onready var wall: TileMapLayer = $Wall
var trawler: Node2D

@export var wall_half_width_cells: int = 60

# how far ahead we always want wall, in world pixels
@export var distance_ahead_pixels: float = 3000.0

# gap between trawler and start of wall, in tiles
@export var nose_gap_tiles: int = 20

# tileset info
@export var tile_source_id: int = 0                # wall.png source
@export var wall_atlas_coord: Vector2i = Vector2i(0, 0)   # wall tile
@export var ground_atlas_coord: Vector2i = Vector2i(0, 1) # ground tile
@export var ground_thickness: int = 3

var wall_height_cells: int
var current_top_y: int
var left_x: int
var right_x: int


func _ready() -> void:
	print("Spawning wall and ground")
	await get_tree().process_frame
	trawler = get_tree().get_first_node_in_group("trawler")
	if trawler == null:
		print("No trawler found")
		push_error("No node in group 'trawler' found.")
		return

	var tile_size: int = int(wall.tile_set.tile_size.x)
	wall_height_cells = int(ceil(distance_ahead_pixels / float(tile_size)))

	_init_bounds_and_generate()


func _init_bounds_and_generate() -> void:
	var trawler_cell := _get_trawler_cell()

	left_x = trawler_cell.x - wall_half_width_cells
	right_x = trawler_cell.x + wall_half_width_cells

	# we want the first wall row to start nose_gap_tiles above the trawler
	# current_top_y is the last generated row + 1, so set it just above that
	current_top_y = trawler_cell.y - nose_gap_tiles + 1

	_ensure_wall_ahead(trawler_cell)
	_generate_ground(trawler_cell)


func _process(_delta: float) -> void:
	if trawler == null:
		return

	var trawler_cell := _get_trawler_cell()
	_ensure_wall_ahead(trawler_cell)
	_generate_ground(trawler_cell)


func _get_trawler_cell() -> Vector2i:
	var local := wall.to_local(trawler.global_position)
	return wall.local_to_map(local)


func _ensure_wall_ahead(trawler_cell: Vector2i) -> void:
	# y decreases as we go up into the wall
	var desired_top_y := trawler_cell.y - wall_height_cells

	# already generated far enough
	if desired_top_y >= current_top_y:
		return

	for x in range(left_x, right_x + 1):
		# start from row just above current_top_y
		for y in range(current_top_y - 1, desired_top_y - 1, -1):
			wall.set_cell(Vector2i(x, y), tile_source_id, wall_atlas_coord)

	current_top_y = desired_top_y


func _generate_ground(trawler_cell: Vector2i) -> void:
	for x in range(left_x, right_x + 1):
		for i in range(ground_thickness):
			var gy := trawler_cell.y + i
			wall.set_cell(Vector2i(x, gy), tile_source_id, ground_atlas_coord)
