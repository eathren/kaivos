extends Node
class_name DungeonLayout

## Generates dungeon layouts using room grid coordinates
## Pure logic - no Godot scene nodes, just data structures

## Room node data structure
class RoomNode:
	var grid_pos: Vector2i  # Position in room grid
	var mask: int = 0  # Door mask - which sides connect to other rooms
	var room_type: String = "combat"  # Room type
	
	func _init(pos: Vector2i = Vector2i.ZERO, type: String = "combat") -> void:
		grid_pos = pos
		room_type = type

## Generate a dungeon layout using drunk walk algorithm
static func generate_layout(max_rooms: int = 10, seed_value: int = -1) -> Array[RoomNode]:
	if seed_value >= 0:
		seed(seed_value)
	
	var rooms: Dictionary = {}  # Vector2i -> RoomNode
	var frontier: Array[RoomNode] = []
	
	# Create start room
	var start := RoomNode.new(Vector2i.ZERO, "start")
	rooms[start.grid_pos] = start
	frontier.append(start)
	
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	
	while rooms.size() < max_rooms and not frontier.is_empty():
		var current: RoomNode = frontier.pop_back()
		
		# Try to branch in each direction
		for dir in directions:
			# Random chance to branch
			if randf() > 0.5:
				continue
			
			var next_pos = current.grid_pos + dir
			
			# Skip if room already exists
			if rooms.has(next_pos):
				continue
			
			# Create new room
			var room := RoomNode.new(next_pos, _choose_room_type(rooms.size(), max_rooms))
			rooms[next_pos] = room
			frontier.append(room)
			
			# Set door bits for both rooms
			var bit_current := _dir_to_bit(dir)
			var bit_next := _dir_to_bit(-dir)
			current.mask |= bit_current
			room.mask |= bit_next
	
	# Convert Dictionary values to typed array
	var result: Array[RoomNode] = []
	for room in rooms.values():
		result.append(room)
	return result

## Choose room type based on progression
static func _choose_room_type(current_count: int, max_rooms: int) -> String:
	var progress := float(current_count) / float(max_rooms)
	
	# Last room is boss
	if current_count == max_rooms - 1:
		return "boss"
	
	# Random special rooms
	var rand := randf()
	if progress > 0.3 and rand < 0.1:
		return "shop"
	elif progress > 0.4 and rand < 0.15:
		return "treasure"
	elif progress > 0.5 and rand < 0.2:
		return "rest"
	
	return "combat"

## Convert direction vector to door bit
static func _dir_to_bit(dir: Vector2i) -> int:
	if dir == Vector2i.UP:
		return 1
	if dir == Vector2i.RIGHT:
		return 2
	if dir == Vector2i.DOWN:
		return 4
	if dir == Vector2i.LEFT:
		return 8
	return 0

## Generate a simple linear layout (good for testing)
static func generate_linear_layout(room_count: int = 5) -> Array[RoomNode]:
	var rooms: Array[RoomNode] = []
	
	for i in range(room_count):
		var room := RoomNode.new(Vector2i(i, 0))
		
		# Determine room type
		if i == 0:
			room.room_type = "start"
			room.mask = 2  # Right door only
		elif i == room_count - 1:
			room.room_type = "boss"
			room.mask = 8  # Left door only
		else:
			room.room_type = "combat"
			room.mask = 2 | 8  # Left and right doors
		
		rooms.append(room)
	
	return rooms
