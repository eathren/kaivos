extends Node2D

@export var laser_damage_per_second: float = 10.0
@export var max_distance: float = 2000.0
@export var tile_step: float = 16.0   # match  tile size

var is_active: bool = true

@onready var wall: TileMapLayer = get_tree().get_first_node_in_group("wall")
@onready var beam: Line2D = $Beam   # or whatever your visual node is

func _process(delta: float) -> void:
	# Hold left mouse to turn the laser off
	var mouse_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	is_active = not mouse_down

	beam.visible = is_active

	if is_active:
		_fire_laser(delta)

func _fire_laser(delta: float) -> void:
	if wall == null:
		return

	var origin: Vector2 = global_position
	var dir: Vector2 = Vector2.UP   # adjust if your trawler faces a different way

	var travelled := 0.0
	var hit_pos := origin + dir * max_distance

	while travelled < max_distance:
		var pos := origin + dir * travelled
		var local := wall.to_local(pos)
		var cell := wall.local_to_map(local)

		if wall.get_cell_source_id(cell) != -1:
			# Damage this cell
			if "damage_cell" in wall:
				wall.damage_cell(cell, laser_damage_per_second * delta)
			hit_pos = pos
			break

		travelled += tile_step

	# Update beam visual from origin to hit_pos
	beam.clear_points()
	beam.add_point(to_local(origin))
	beam.add_point(to_local(hit_pos))
