extends Node2D
class_name RoomTemplate

## Base class for all room templates
## Each room has a fixed size, tile layers, and marker positions for doors, loot, and enemies

@export_enum("start", "combat", "shop", "boss", "treasure", "rest") var room_type: String = "combat"
@export_flags("Up:1", "Right:2", "Down:4", "Left:8") var door_mask: int = 0  ## Which sides have doors

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var markers: Node2D = $Markers

func _ready() -> void:
	add_to_group("room_template")

## Get all door marker positions
func get_door_markers() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("room_door"):
		if node.is_inside_tree() and is_ancestor_of(node):
			result.append(node)
	return result

## Get all loot spawn marker positions
func get_loot_markers() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("room_loot"):
		if node.is_inside_tree() and is_ancestor_of(node):
			result.append(node)
	return result

## Get all enemy spawn marker positions
func get_enemy_markers() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("room_enemy"):
		if node.is_inside_tree() and is_ancestor_of(node):
			result.append(node)
	return result

## Check if this room has a door in the given direction (bit flag)
func has_door(direction_bit: int) -> bool:
	return (door_mask & direction_bit) != 0
