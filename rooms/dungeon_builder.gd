extends Node2D

## Example Dungeon Builder
## Shows how to use the room template system to generate and populate a dungeon

const RoomConstants = preload("res://rooms/room_constants.gd")

@export var room_count: int = 10
@export var use_linear_layout: bool = false  # Set true for simple testing

var active_rooms: Array[RoomTemplate] = []

func _ready() -> void:
	# Wait a frame for autoloads to initialize
	await get_tree().process_frame
	build_dungeon()

func build_dungeon() -> void:
	# Generate layout
	var layout: Array
	if use_linear_layout:
		layout = DungeonLayout.generate_linear_layout(5)
	else:
		layout = DungeonLayout.generate_layout(room_count)
	
	print("Generated %d rooms" % layout.size())
	
	# Instantiate rooms from templates
	for room_node in layout:
		_create_room(room_node)
	
	print("Dungeon built with %d room instances" % active_rooms.size())

func _create_room(room_node: DungeonLayout.RoomNode) -> void:
	# Get matching room template
	var scene: PackedScene = RoomLibrary.get_random(room_node.mask, room_node.room_type)
	
	if scene == null:
		push_warning("No template found for mask=%d type=%s" % [room_node.mask, room_node.room_type])
		return
	
	# Instantiate room
	var room_inst: RoomTemplate = scene.instantiate()
	add_child(room_inst)
	
	# Position based on grid coordinates
	room_inst.position = Vector2(room_node.grid_pos) * Vector2(RoomConstants.ROOM_SIZE_PX)
	
	# Store reference
	active_rooms.append(room_inst)
	
	# Populate room with enemies and loot
	_populate_room(room_inst)

func _populate_room(room: RoomTemplate) -> void:
	# Spawn enemies
	for marker in room.get_enemy_markers():
		_spawn_enemy_at(marker.global_position)
	
	# Spawn loot (40% chance per marker)
	for marker in room.get_loot_markers():
		if randf() < 0.4:
			_spawn_loot_at(marker.global_position)

func _spawn_enemy_at(pos: Vector2) -> void:
	# Replace with your actual enemy spawning
	print("Spawn enemy at: ", pos)
	# Example:
	# var enemy = preload("res://entities/enemies/basic_enemy/basic_enemy.tscn").instantiate()
	# get_tree().current_scene.add_child(enemy)
	# enemy.global_position = pos

func _spawn_loot_at(pos: Vector2) -> void:
	# Replace with your actual loot spawning
	print("Spawn loot at: ", pos)
	# Example:
	# var loot = preload("res://entities/items/health_pickup/health_pickup.tscn").instantiate()
	# get_tree().current_scene.add_child(loot)
	# loot.global_position = pos
