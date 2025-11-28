extends Node2D
class_name ShipDock

## Ship dock that spawns a ship and acts as turret when docked

signal ship_undocked(dock: ShipDock)
signal ship_docked(dock: ShipDock)

@export var ship_scene: PackedScene = preload("res://scenes/gameplay/player/player_ship.tscn")
@export var dock_side: String = "left"  # "left" or "right" for sprite flipping

@onready var sprite: Sprite2D = $Sprite2D
@onready var dock_marker: Marker2D = $DockMarker
@onready var interaction_area: Area2D = $InteractionArea

var docked_ship: Node2D = null
var player_in_range: bool = false
var is_spawning: bool = false

func _ready() -> void:
	add_to_group("ship_dock")
	
	# Flip sprite based on side
	if sprite:
		sprite.flip_h = (dock_side == "right")
	
	# Spawn initial ship and dock it
	_spawn_docked_ship()
	
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _spawn_docked_ship() -> void:
	"""Spawn a ship and immediately dock it as a turret"""
	if is_spawning or docked_ship != null:
		return
	
	is_spawning = true
	
	if not ship_scene:
		push_error("ShipDock: No ship scene assigned!")
		is_spawning = false
		return
	
	var ship := ship_scene.instantiate()
	get_tree().root.get_node("Main/CurrentLevel").add_child(ship)
	ship.global_position = global_position
	ship.add_to_group("docked_turret")
	
	docked_ship = ship
	docked_ship.visible = true
	
	# Enable turret mode on the ship
	if docked_ship.has_method("set_turret_mode"):
		docked_ship.set_turret_mode(true)
	
	ship_docked.emit(self)
	is_spawning = false
	print("ShipDock: Ship spawned and docked as turret at ", global_position)

func _process(_delta: float) -> void:
	# Update docked ship position to follow dock
	if docked_ship and is_instance_valid(docked_ship):
		docked_ship.global_position = global_position
		docked_ship.global_rotation = global_rotation
	
	# Handle player interaction to undock (only if this dock has a ship)
	if player_in_range and docked_ship != null and Input.is_action_just_pressed("interact"):
		_undock_ship()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if docked_ship != null and is_instance_valid(docked_ship):
			player_in_range = true
			_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		_hide_prompt()

func _undock_ship() -> void:
	"""Undock the ship and give control to player"""
	if docked_ship == null or not is_instance_valid(docked_ship):
		return
	
	_hide_prompt()
	
	# Find player (crew member)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		print("ShipDock: No player found to undock ship")
		return
	
	print("ShipDock: Undocking ship - transferring control to player")
	
	# Disable turret mode
	if docked_ship.has_method("set_turret_mode"):
		docked_ship.set_turret_mode(false)
	
	# Remove from docked turret group
	docked_ship.remove_from_group("docked_turret")
	
	# Transfer control to player
	if docked_ship.has_method("take_control_from_player"):
		player.deactivate()
		docked_ship.take_control_from_player(player)
		
		# Apply spawn offset based on dock side
		var offset := Vector2(80, 0) if dock_side == "right" else Vector2(-80, 0)
		offset = offset.rotated(get_parent().global_rotation)  # Rotate by trawler rotation
		docked_ship.global_position = global_position + offset
	
	ship_undocked.emit(self)
	docked_ship = null

func dock_ship(ship: Node2D) -> void:
	"""Dock a ship back to this dock"""
	if docked_ship != null:
		print("ShipDock: Dock already occupied")
		return
	
	docked_ship = ship
	docked_ship.global_position = global_position
	docked_ship.add_to_group("docked_turret")
	
	# Enable turret mode
	if docked_ship.has_method("set_turret_mode"):
		docked_ship.set_turret_mode(true)
	
	ship_docked.emit(self)
	print("ShipDock: Ship docked at ", global_position)

func _show_prompt() -> void:
	var ui := get_tree().root.get_node_or_null("Main/UI/InteractionPrompt")
	if ui and ui.has_method("show_interaction_prompt"):
		ui.show_interaction_prompt("Press E to undock ship")

func _hide_prompt() -> void:
	var ui := get_tree().root.get_node_or_null("Main/UI/InteractionPrompt")
	if ui and ui.has_method("hide_interaction_prompt"):
		ui.hide_interaction_prompt()

func is_occupied() -> bool:
	return docked_ship != null and is_instance_valid(docked_ship)

