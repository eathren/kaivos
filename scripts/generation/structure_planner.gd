extends RefCounted
class_name StructurePlanner

## High-level dungeon structure generator
## Creates rooms, corridors, and features BEFORE WFC runs
## WFC then decorates/fills based on this structure

enum CellType {
	UNDEFINED,    # WFC can decide
	ROOM,         # Force room floor
	CORRIDOR,     # Force corridor
	WALL,         # Force wall
	DOOR,         # Force door
	TREASURE,     # Force treasure room
	CLEARING      # Open area (for trawler start)
}

class StructureCell:
	var type: CellType = CellType.UNDEFINED
	var metadata: Dictionary = {}  # Extra info like room_id, biome, etc.

class Room:
	var bounds: Rect2i  # x, y, width, height in tiles
	var type: String = "normal"  # normal, treasure, boss, etc.
	var id: int = -1
	
	func _init(rect: Rect2i, room_type: String = "normal", room_id: int = -1):
		bounds = rect
		type = room_type
		id = room_id
	
	func center() -> Vector2i:
		return Vector2i(bounds.position.x + bounds.size.x / 2, bounds.position.y + bounds.size.y / 2)

var rng: RandomNumberGenerator
var grid: Dictionary  # Vector2i -> StructureCell
var rooms: Array[Room] = []
var corridors: Array[Array] = []  # Array of cell arrays

func _init():
	rng = RandomNumberGenerator.new()

## Generate high-level structure for the mine
func generate_mine_structure(
	seed_value: int,
	left_x: int, right_x: int,
	top_y: int, bottom_y: int,
	clearing_bounds: Rect2i
) -> Dictionary:
	"""
	Returns a Dictionary of Vector2i -> CellType defining the structure
	"""
	rng.seed = hash(seed_value)
	grid.clear()
	rooms.clear()
	corridors.clear()
	
	# Mark clearing area
	_mark_clearing(clearing_bounds)
	
	# Generate rooms in the mine shaft
	var vertical_sections = 10  # Divide mine into vertical slices
	var section_height = (bottom_y - top_y) / vertical_sections
	
	for section_idx in range(vertical_sections):
		var section_y_start = top_y + section_idx * section_height
		var section_y_end = section_y_start + section_height
		
		# Skip the clearing section
		if section_y_start < clearing_bounds.end.y and section_y_end > clearing_bounds.position.y:
			continue
		
		# Generate 2-4 rooms per section
		var rooms_in_section = rng.randi_range(2, 4)
		
		for i in range(rooms_in_section):
			_generate_room_in_bounds(
				left_x + 50,  # Add margin from walls
				right_x - 50,
				section_y_start + 20,
				section_y_end - 20
			)
	
	# Connect rooms with corridors
	_connect_rooms()
	
	# Return the grid
	return _grid_to_dict()

## Mark the clearing area (starting zone)
func _mark_clearing(bounds: Rect2i) -> void:
	"""Mark the trawler clearing as open space"""
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell = StructureCell.new()
			cell.type = CellType.CLEARING
			grid[Vector2i(x, y)] = cell

## Generate a single room in the given bounds
func _generate_room_in_bounds(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	var room_width = rng.randi_range(8, 16)
	var room_height = rng.randi_range(6, 12)
	
	# Pick random position
	var x = rng.randi_range(min_x, max_x - room_width)
	var y = rng.randi_range(min_y, max_y - room_height)
	
	var room_rect = Rect2i(x, y, room_width, room_height)
	
	# Check for overlap with existing rooms
	for existing_room in rooms:
		if room_rect.intersects(existing_room.bounds.grow(3)):  # 3 tile buffer
			return  # Skip this room
	
	# Create room
	var room_type = "normal"
	if rng.randf() < 0.1:
		room_type = "treasure"
	
	var room = Room.new(room_rect, room_type, rooms.size())
	rooms.append(room)
	
	# Mark cells as room floor
	for ry in range(room_rect.position.y, room_rect.end.y):
		for rx in range(room_rect.position.x, room_rect.end.x):
			var cell = StructureCell.new()
			cell.type = CellType.ROOM
			cell.metadata["room_id"] = room.id
			cell.metadata["room_type"] = room_type
			grid[Vector2i(rx, ry)] = cell
	
	# Mark walls around room
	_mark_room_walls(room_rect)

## Mark walls around a room
func _mark_room_walls(room_rect: Rect2i) -> void:
	# Top and bottom walls
	for x in range(room_rect.position.x - 1, room_rect.end.x + 1):
		_mark_wall(Vector2i(x, room_rect.position.y - 1))
		_mark_wall(Vector2i(x, room_rect.end.y))
	
	# Left and right walls
	for y in range(room_rect.position.y, room_rect.end.y):
		_mark_wall(Vector2i(room_rect.position.x - 1, y))
		_mark_wall(Vector2i(room_rect.end.x, y))

func _mark_wall(pos: Vector2i) -> void:
	if not grid.has(pos):
		var cell = StructureCell.new()
		cell.type = CellType.WALL
		grid[pos] = cell

## Connect rooms with corridors
func _connect_rooms() -> void:
	if rooms.size() < 2:
		return
	
	# Sort rooms by Y position (top to bottom)
	var sorted_rooms = rooms.duplicate()
	sorted_rooms.sort_custom(func(a, b): return a.center().y < b.center().y)
	
	# Connect each room to the next one below it
	for i in range(sorted_rooms.size() - 1):
		var room_a = sorted_rooms[i]
		var room_b = sorted_rooms[i + 1]
		
		_create_corridor(room_a.center(), room_b.center())

## Create a corridor between two points
func _create_corridor(from: Vector2i, to: Vector2i) -> void:
	var corridor_cells: Array = []
	var current = from
	
	# L-shaped corridor: horizontal first, then vertical
	# Horizontal segment
	var dx = sign(to.x - from.x)
	while current.x != to.x:
		_mark_corridor(current)
		corridor_cells.append(current)
		current.x += dx
	
	# Vertical segment
	var dy = sign(to.y - from.y)
	while current.y != to.y:
		_mark_corridor(current)
		corridor_cells.append(current)
		current.y += dy
	
	corridors.append(corridor_cells)
	
	# Place doors at corridor-room junctions
	_place_doors(from)
	_place_doors(to)

func _mark_corridor(pos: Vector2i) -> void:
	# Only mark if not already a room or clearing
	if grid.has(pos):
		var cell = grid[pos]
		if cell.type == CellType.ROOM or cell.type == CellType.CLEARING:
			return
	
	var cell = StructureCell.new()
	cell.type = CellType.CORRIDOR
	grid[pos] = cell
	
	# Add walls on sides
	for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var wall_pos = pos + offset
		if not grid.has(wall_pos):
			_mark_wall(wall_pos)

func _place_doors(pos: Vector2i) -> void:
	# Check if position is at junction between corridor and room
	var adjacent_to_room = false
	var adjacent_to_corridor = false
	
	for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check_pos = pos + offset
		if grid.has(check_pos):
			var cell = grid[check_pos]
			if cell.type == CellType.ROOM:
				adjacent_to_room = true
			elif cell.type == CellType.CORRIDOR:
				adjacent_to_corridor = true
	
	if adjacent_to_room and adjacent_to_corridor:
		# This is a junction - place door
		if grid.has(pos):
			grid[pos].type = CellType.DOOR

## Convert grid to simple dictionary
func _grid_to_dict() -> Dictionary:
	var result = {}
	for pos in grid:
		result[pos] = grid[pos].type
	return result

## Get structure type at position (for WFC to use)
func get_structure_at(pos: Vector2i) -> CellType:
	if grid.has(pos):
		return grid[pos].type
	return CellType.UNDEFINED

## Get all room data for spawning scene-based buildings
func get_rooms() -> Array[Room]:
	return rooms

## Get room metadata at position
func get_room_at(pos: Vector2i) -> Room:
	if grid.has(pos) and grid[pos].metadata.has("room_id"):
		var room_id = grid[pos].metadata["room_id"]
		for room in rooms:
			if room.id == room_id:
				return room
	return null
