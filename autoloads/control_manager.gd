extends Node

## Manages switching between crew member and ship control
## Enforces "one ship out at a time" rule

var camera: Camera2D = null
var crew: CharacterBody2D = null
var trawler: Node2D = null

var ship_scene: PackedScene = preload("res://entities/player/ships/player_ship/player_ship.tscn")
var active_ship: Node2D = null
var active_dock: Node2D = null
var docks: Array = []  # Array of ShipDock nodes

func _ready() -> void:
	# Wait for scene to load before finding nodes
	await get_tree().process_frame
	_find_scene_nodes()

func _find_scene_nodes() -> void:
	"""Find camera, crew, trawler, and docks in the scene"""
	var root := get_tree().current_scene
	if not root:
		return
	
	# Find camera (should be child of crew initially)
	camera = _find_node_recursive(root, "Camera2D") as Camera2D
	
	# Find crew
	crew = get_tree().get_first_node_in_group("player")
	
	# Find trawler
	trawler = get_tree().get_first_node_in_group("trawler")
	
	# Find all ship docks
	docks = get_tree().get_nodes_in_group("ship_dock")
	
	print("ControlManager: Found ", docks.size(), " docks")

func _find_node_recursive(node: Node, node_name: String) -> Node:
	"""Recursively search for a node by name"""
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result := _find_node_recursive(child, node_name)
		if result:
			return result
	return null

func request_undock_from_ladder(from_dock: Node2D = null) -> void:
	"""Called when player presses interact on a ladder inside trawler"""
	if active_ship:
		print("ControlManager: Ship already out")
		return
	
	# Pick first available dock if none specified
	var dock := from_dock
	if not dock and not docks.is_empty():
		dock = docks[0]
	
	if not dock:
		push_error("ControlManager: No dock available")
		return
	
	active_dock = dock
	
	# Spawn ship at dock
	active_ship = ship_scene.instantiate()
	get_tree().current_scene.add_child(active_ship)
	active_ship.global_position = dock.global_position
	active_ship.global_rotation = dock.global_rotation
	
	# Set ship references
	if active_ship.has_method("set_control_manager"):
		active_ship.set_control_manager(self)
	if active_ship.has_method("set_home_dock"):
		active_ship.set_home_dock(dock)
	
	# Activate ship
	if active_ship.has_method("activate"):
		active_ship.activate()
	
	# Hide crew and switch camera
	if crew:
		crew.visible = false
		if crew.has_method("deactivate"):
			crew.deactivate()
	
	_set_camera_target(active_ship)
	
	print("ControlManager: Undocked ship from ", dock.name)

func dock_current_ship() -> void:
	"""Called when ship wants to dock"""
	if not active_ship or not active_dock:
		return
	
	# Snap ship to dock position (optional smoothing)
	active_ship.global_position = active_dock.global_position
	
	# Store crew position for respawn
	var crew_spawn_pos := active_dock.global_position
	if trawler:
		# Spawn crew inside trawler near the ladder
		crew_spawn_pos = trawler.global_position
	
	# Delete ship
	active_ship.queue_free()
	active_ship = null
	active_dock = null
	
	# Reactivate crew
	if crew:
		crew.global_position = crew_spawn_pos
		crew.visible = true
		if crew.has_method("activate"):
			crew.activate()
	
	_set_camera_target(crew)
	
	print("ControlManager: Ship docked")

func _set_camera_target(target: Node2D) -> void:
	"""Move camera to follow a new target"""
	if not camera or not target:
		return
	
	# Simple approach: reparent camera to target
	if camera.get_parent():
		camera.get_parent().remove_child(camera)
	
	target.add_child(camera)
	camera.position = Vector2.ZERO
	
	print("ControlManager: Camera following ", target.name)

func is_ship_active() -> bool:
	return active_ship != null
