extends TileMapLayer
class_name ReusableTileMapLayer

## Reusable TileMapLayer with common functionality
## Can be used for floors, walls, decorations, etc.

enum LayerType {
	FLOOR,
	WALL,
	DECORATION,
	BACKGROUND
}

@export var layer_type: LayerType = LayerType.FLOOR
@export var tile_source_id: int = 0
@export var auto_setup: bool = true

# Common tile coordinates (adjust based on your tileset)
@export_group("Tile Coordinates")
@export var ground_coord: Vector2i = Vector2i(0, 0)
@export var wall_center_coord: Vector2i = Vector2i(1, 0)
@export var wall_edge_coords: Array[Vector2i] = [Vector2i(2, 0), Vector2i(3, 0)]
@export var wall_face_coords: Array[Vector2i] = [Vector2i(4, 0), Vector2i(5, 0)]

# Tile health system (for destructible tiles)
@export_group("Tile Health")
@export var tiles_have_health: bool = false
@export var default_tile_health: float = 100.0
var tile_health: Dictionary = {}  # Vector2i -> float

func _ready() -> void:
	if auto_setup:
		_setup_layer()

func _setup_layer() -> void:
	match layer_type:
		LayerType.FLOOR:
			z_index = -1
			collision_enabled = false
		LayerType.WALL:
			z_index = 0
			collision_enabled = true
		LayerType.DECORATION:
			z_index = 1
			collision_enabled = false
		LayerType.BACKGROUND:
			z_index = -2
			collision_enabled = false

## Fill a rectangular area with tiles
func fill_rect(rect: Rect2i, atlas_coord: Vector2i, source_id: int = -1) -> void:
	if source_id == -1:
		source_id = tile_source_id
	
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			set_cell(Vector2i(x, y), source_id, atlas_coord)

## Fill a circle area with tiles
func fill_circle(center: Vector2i, radius: int, atlas_coord: Vector2i, source_id: int = -1) -> void:
	if source_id == -1:
		source_id = tile_source_id
	
	var radius_sq := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var pos := Vector2i(x, y)
			var dist_sq := pos.distance_squared_to(center)
			if dist_sq <= radius_sq:
				set_cell(pos, source_id, atlas_coord)

## Clear a rectangular area
func clear_rect(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			erase_cell(Vector2i(x, y))

## Damage a tile (for destructible tiles)
func damage_cell(cell: Vector2i, damage: float) -> bool:
	if not tiles_have_health:
		erase_cell(cell)
		return true
	
	# Initialize health if not tracked
	if not tile_health.has(cell):
		tile_health[cell] = default_tile_health
	
	# Apply damage
	tile_health[cell] -= damage
	
	# Destroy tile if health depleted
	if tile_health[cell] <= 0:
		erase_cell(cell)
		tile_health.erase(cell)
		return true
	
	return false

## Get tile health
func get_tile_health(cell: Vector2i) -> float:
	if not tiles_have_health:
		return 0.0
	return tile_health.get(cell, default_tile_health)

## Set tile health
func set_tile_health(cell: Vector2i, health: float) -> void:
	if tiles_have_health:
		tile_health[cell] = health

## Check if a cell has a tile
func has_tile(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1

## Get all tiles in the layer
func get_all_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var used_cells := get_used_cells()
	for cell in used_cells:
		tiles.append(cell)
	return tiles

## Get tiles in a rectangular area
func get_tiles_in_rect(rect: Rect2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var cell := Vector2i(x, y)
			if has_tile(cell):
				tiles.append(cell)
	return tiles

## Convert world position to tile coordinates
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(world_pos))

## Convert tile coordinates to world position
func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return to_global(map_to_local(tile_pos))
