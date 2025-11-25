extends Node

var ground_tilemap: TileMapLayer
var wall_tilemap: TileMapLayer

var _spawn_cells: Array[Vector2i] = []


func setup(ground: TileMapLayer, walls: TileMapLayer) -> void:
	ground_tilemap = ground
	wall_tilemap = walls
	_rebuild_spawn_cells()


func _rebuild_spawn_cells() -> void:
	_spawn_cells.clear()
	if ground_tilemap == null or wall_tilemap == null:
		push_error("SpawnManager.setup was not called correctly")
		return

	# Build a fast lookup of wall cells
	var wall_cells := {}
	for cell in wall_tilemap.get_used_cells(0):
		wall_cells[cell] = true

	# Any ground cell that is not a wall is a candidate
	for cell in ground_tilemap.get_used_cells(0):
		if not wall_cells.has(cell):
			_spawn_cells.append(cell)


func get_spawn_position() -> Vector2:
	if _spawn_cells.is_empty():
		push_warning("SpawnManager has no spawn cells")
		return Vector2.ZERO

	var idx := randi() % _spawn_cells.size()
	var cell: Vector2i = _spawn_cells[idx]

	# Tile coords -> global coordinates
	var local_pos := ground_tilemap.map_to_local(cell)
	return ground_tilemap.to_global(local_pos)


func spawn(scene: PackedScene, parent: Node = null) -> Node2D:
	var pos := get_spawn_position()
	var inst := scene.instantiate() as Node2D

	if parent == null:
		parent = get_tree().current_scene

	parent.add_child(inst)
	inst.global_position = pos
	return inst
