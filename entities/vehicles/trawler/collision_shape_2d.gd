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
	# Only check input if player is in zone
	if player_in_zone == null:
		return
	
	# Only the nearest dock should respond
	if not _is_nearest_ladder_dock():
		return
	
	# Check for interact input
	if Input.is_action_just_pressed("interact"):
		# Find the player's controller
		var controller := _find_player_controller()
		if controller and controller.has_method("control_ship"):
			# Find nearest ship dock
			var nearest_dock := _find_nearest_ship_dock()
			if nearest_dock:
				controller.control_ship(nearest_dock)
				_hide_prompt()

func _find_player_controller() -> Node:
	"""Find the PlayerController that owns this crew member"""
	# For single player, just find the first controller
	var controllers := get_tree().get_nodes_in_group("player_controller")
	if controllers.is_empty():
		return null
	return controllers[0]

func _find_nearest_ship_dock() -> Node2D:
	"""Find the nearest available ship dock"""
	var docks := get_tree().get_nodes_in_group("ship_dock")
	var nearest: Node2D = null
	var nearest_dist := INF
	
	for dock in docks:
		if not is_instance_valid(dock):
			continue
		
		# Skip occupied docks
		if dock.has_method("is_occupied") and dock.is_occupied():
			continue
		
		var dist := global_position.distance_to(dock.global_position)
		if dist < nearest_dist:
			nearest = dock
			nearest_dist = dist
	
	return nearest

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
