extends Node2D

enum DockSide {
	LEFT,
	RIGHT
}

@export var ship_scene: PackedScene      # assign PlayerShip scene in the inspector
@export var side: DockSide = DockSide.LEFT

var area: Area2D
var dock_marker: Marker2D
var sprite: Sprite2D

var player_in_zone: CharacterBody2D = null
var is_spawning: bool = false  # Prevent multiple ship spawns

func _ready() -> void:
	add_to_group("ladder_dock")
	
	# Get nodes manually to ensure they're found
	area = get_node_or_null("Area2D")
	dock_marker = get_node_or_null("DockerMarker")
	sprite = get_node_or_null("Sprite2D")
	
	if area == null:
		push_error("LadderDock: Area2D not found")
		return
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_update_sprite_flip()

func _on_body_entered(body: Node) -> void:
	print("LadderDock: Body entered - ", body.name, " Groups: ", body.get_groups())
	if body.is_in_group("player"):
		player_in_zone = body as CharacterBody2D
		print("LadderDock: Player entered zone")
		# Show UI prompt
		_show_prompt()

func _on_body_exited(body: Node) -> void:
	if body == player_in_zone:
		player_in_zone = null
		print("LadderDock: Player exited zone")
		# Hide UI prompt
		_hide_prompt()

func _show_prompt() -> void:
	# Show "Press E to board ship" message
	var ui := get_tree().root.get_node_or_null("Main/UI")
	if ui and ui.has_method("show_interaction_prompt"):
		ui.show_interaction_prompt("Press E to board ship")

func _hide_prompt() -> void:
	var ui := get_tree().root.get_node_or_null("Main/UI")
	if ui and ui.has_method("hide_interaction_prompt"):
		ui.hide_interaction_prompt()

func _process(_delta: float) -> void:
	# Only check input if player is in zone and we're not already spawning
	if player_in_zone == null or is_spawning:
		return
	
	# Global check: prevent any dock from spawning if another is already spawning
	if GameState and GameState.is_spawning_player_ship:
		return
	
	# Only the nearest dock should respond
	if not _is_nearest_ladder_dock():
		return
	
	# Check for interact input
	if Input.is_action_just_pressed("interact"):
		# Double-check no ship exists
		var existing_ships := get_tree().get_nodes_in_group("player_ship")
		if not existing_ships.is_empty():
			print("LadderDock: Ship already exists, cannot spawn another")
			return
		
		_board_ship()

func _board_ship() -> void:
	if player_in_zone == null or is_spawning:
		return
	
	# Global lock
	if GameState and GameState.is_spawning_player_ship:
		return
	
	if ship_scene == null:
		push_warning("LadderDock: No ship scene assigned")
		return

	is_spawning = true
	if GameState:
		GameState.is_spawning_player_ship = true
	_hide_prompt()

	# 1. Deactivate player on foot
	player_in_zone.deactivate()

	# 2. Spawn ship outside the trawler (as sibling to trawler in the level)
	var level := get_tree().current_scene.get_node_or_null("Level_Mine")
	if level == null:
		level = get_tree().current_scene
	
	var ship := ship_scene.instantiate()
	level.add_child(ship)
	
	# Connect to ship's tree_exiting signal to reset spawning flag when it's deleted
	ship.tree_exiting.connect(_on_ship_deleted)

	# Position ship outside the trawler, offset to the side
	var spawn_offset := Vector2.ZERO
	if side == DockSide.LEFT:
		spawn_offset = Vector2(-80, 0)  # 80 pixels to the left
	else:
		spawn_offset = Vector2(80, 0)   # 80 pixels to the right
	
	# Get trawler to apply offset relative to its rotation
	var trawler := get_parent().get_parent()
	ship.global_position = dock_marker.global_position + spawn_offset.rotated(trawler.rotation)
	ship.rotation = trawler.rotation  # Match trawler rotation

	# 3. Give control to the ship
	ship.call_deferred("take_control_from_player", player_in_zone)
	
	print("LadderDock: Player boarded ship at ", ship.global_position)

func _on_ship_deleted() -> void:
	"""Called when the ship is deleted, allowing new ships to spawn"""
	is_spawning = false
	if GameState:
		GameState.is_spawning_player_ship = false
	print("LadderDock: Ship deleted, can spawn new ship")

func _update_sprite_flip() -> void:
	if sprite:
		# Flip horizontally for right side
		sprite.flip_h = (side == DockSide.RIGHT)

func _is_nearest_ladder_dock() -> bool:
	"""Check if this is the nearest ladder dock to the player"""
	if player_in_zone == null:
		return false
	
	var my_distance: float = global_position.distance_to(player_in_zone.global_position)
	
	# Check all other ladder docks
	var all_ladder_docks := get_tree().get_nodes_in_group("ladder_dock")
	for dock in all_ladder_docks:
		if dock == self or not is_instance_valid(dock):
			continue
		
		# Check if dock has a player in range
		if "player_in_zone" in dock and dock.player_in_zone != null:
			var other_distance: float = dock.global_position.distance_to(player_in_zone.global_position)
			if other_distance < my_distance:
				return false
	
	return true
