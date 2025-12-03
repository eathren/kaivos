extends Node2D

## Test scene for room system - standalone test without full mine generation

const RoomConstants = preload("res://rooms/room_constants.gd")

@export var test_linear_layout: bool = true
@export var room_count: int = 5

func _ready() -> void:
	# Wait for autoloads
	await get_tree().process_frame
	_test_rooms()

func _test_rooms() -> void:
	print("=== Room System Test ===")
	
	# Generate simple layout
	var layout: Array
	if test_linear_layout:
		layout = DungeonLayout.generate_linear_layout(room_count)
		print("Generated linear layout with %d rooms" % layout.size())
	else:
		layout = DungeonLayout.generate_layout(room_count)
		print("Generated dungeon layout with %d rooms" % layout.size())
	
	# Spawn rooms
	for room_node in layout:
		_spawn_room(room_node)
	
	print("=== Test Complete ===")

func _spawn_room(room_node: DungeonLayout.RoomNode) -> void:
	var scene := RoomLibrary.get_random(room_node.mask, room_node.room_type)
	
	if scene == null:
		print("ERROR: No room found for mask=%d type=%s" % [room_node.mask, room_node.room_type])
		return
	
	var room: RoomTemplate = scene.instantiate()
	add_child(room)
	room.position = Vector2(room_node.grid_pos) * Vector2(RoomConstants.ROOM_SIZE_PX)
	
	print("Spawned %s room at grid %s (world %s)" % [room_node.room_type, room_node.grid_pos, room.position])
	print("  - Door mask: %d" % room_node.mask)
	print("  - Enemy markers: %d" % room.get_enemy_markers().size())
	print("  - Loot markers: %d" % room.get_loot_markers().size())
