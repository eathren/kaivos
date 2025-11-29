extends Node2D
class_name ShipDock

## Ship dock that spawns and holds ships
## Multiple players can use any dock

enum DockPosition {
	LEFT,
	RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

@export var dock_position: DockPosition = DockPosition.LEFT
@export var home_ship_id: int = 0
@export var dock_radius: float = 64.0

var docked_ship: Node2D = null

func _ready() -> void:
	add_to_group("ship_dock")

func get_or_spawn_ship(ship_scene: PackedScene) -> Node2D:
	"""Get the docked ship or spawn a new one"""
	if docked_ship and is_instance_valid(docked_ship):
		docked_ship.visible = true
		return docked_ship
	
	if not ship_scene:
		push_error("ShipDock: No ship scene provided")
		return null
	
	var ship := ship_scene.instantiate()
	get_tree().current_scene.add_child(ship)
	docked_ship = ship
	ship.global_position = global_position
	
	return ship

func receive_ship(ship: Node2D) -> void:
	"""Dock receives a ship"""
	docked_ship = ship
	ship.global_position = global_position
	ship.visible = false

func get_crew_spawn_position() -> Vector2:
	"""Where crew spawns when exiting ship"""
	# Spawn crew inside trawler (parent should be trawler)
	var trawler := get_parent()
	if trawler:
		return trawler.global_position
	return global_position + Vector2(0, 32)

func is_occupied() -> bool:
	return docked_ship != null and is_instance_valid(docked_ship) and docked_ship.visible
