## Casts a laser along a raycast, emitting particles on the impact point.
## Use `is_casting` to make the laser fire and stop.
## You can attach it to a weapon or a ship; the laser will rotate with its parent.
@tool
extends RayCast2D

## Speed at which the laser extends when first fired, in pixels per seconds.
@export var cast_speed := 7000.0
## Maximum length of the laser in pixels.
@export var max_length := 1400.0
## Distance in pixels from the origin to start drawing and firing the laser.
@export var start_distance := 40.0
## Base duration of the tween animation in seconds.
@export var growth_time := 0.1
@export var color := Color.WHITE: set = set_color

## If `true`, the laser is firing.
## It plays appearing and disappearing animations when it's not animating.
## See `appear()` and `disappear()` for more information.
@export var is_casting := false: set = set_is_casting

var tween: Tween = null

@onready var line_2d: Line2D = %Line2D
@onready var casting_particles: GPUParticles2D = %CastingParticles2D
@onready var collision_particles: GPUParticles2D = %CollisionParticles2D
@onready var beam_particles: GPUParticles2D = %BeamParticles2D

@onready var line_width := line_2d.width

# Mining state
var mining_timer: float = 0.0
var mining_delay: float = 1.0  # 1 second delay before deleting walls
var current_mining_cell: Vector2i = Vector2i(-99999, -99999)  # Invalid cell by default


func _ready() -> void:
	set_color(color)
	set_is_casting(is_casting)
	line_2d.points[0] = Vector2.RIGHT * start_distance
	line_2d.points[1] = Vector2.ZERO
	line_2d.visible = false
	casting_particles.position = line_2d.points[0]

	if not Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	target_position = target_position.move_toward(Vector2.RIGHT * max_length, cast_speed * delta)

	var laser_end_position := target_position
	force_raycast_update()

	var is_hitting_wall := false
	if is_colliding():
		laser_end_position = to_local(get_collision_point())
		collision_particles.global_rotation = get_collision_normal().angle()
		collision_particles.position = laser_end_position
		
		# Check if we're hitting a wall tilemap
		var collider = get_collider()
		if collider is TileMapLayer:
			is_hitting_wall = true
			_handle_wall_mining(collider, delta)

	# Reset mining if not hitting a wall
	if not is_hitting_wall:
		mining_timer = 0.0
		current_mining_cell = Vector2i(-99999, -99999)

	line_2d.points[1] = laser_end_position

	var laser_start_position := line_2d.points[0]
	beam_particles.position = laser_start_position + (laser_end_position - laser_start_position) * 0.5
	beam_particles.process_material.emission_box_extents.x = laser_end_position.distance_to(laser_start_position) * 0.5

	collision_particles.emitting = is_colliding()

func _handle_wall_mining(tilemap: TileMapLayer, delta: float) -> void:
	"""Mine walls after a delay"""
	var collision_point := get_collision_point()
	var tile_pos := tilemap.local_to_map(tilemap.to_local(collision_point))
	
	# Check if it's a wall tile (source_id 5, atlas_coord (1,1))
	var tile_data := tilemap.get_cell_source_id(tile_pos)
	if tile_data != 5:  # Not a wall tile
		mining_timer = 0.0
		current_mining_cell = Vector2i(-99999, -99999)
		return
	
	var atlas_coord := tilemap.get_cell_atlas_coords(tile_pos)
	if atlas_coord != Vector2i(1, 1):  # Not the correct wall type
		mining_timer = 0.0
		current_mining_cell = Vector2i(-99999, -99999)
		return
	
	# Check if we're mining a new cell
	if tile_pos != current_mining_cell:
		current_mining_cell = tile_pos
		mining_timer = 0.0
	
	# Accumulate mining time
	mining_timer += delta
	
	# Delete wall after delay
	if mining_timer >= mining_delay:
		tilemap.erase_cell(tile_pos)
		mining_timer = 0.0
		current_mining_cell = Vector2i(-99999, -99999)


func set_is_casting(new_value: bool) -> void:
	if is_casting == new_value:
		return
	is_casting = new_value
	set_physics_process(is_casting)

	if beam_particles == null:
		return

	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting

	if is_casting:
		var laser_start := Vector2.RIGHT * start_distance
		line_2d.points[0] = laser_start
		line_2d.points[1] = laser_start
		casting_particles.position = laser_start

		appear()
	else:
		target_position = Vector2.ZERO
		collision_particles.emitting = false
		disappear()


func appear() -> void:
	line_2d.visible = true
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(line_2d, "width", line_width, growth_time * 2.0).from(0.0)


func disappear() -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(line_2d, "width", 0.0, growth_time).from_current()
	tween.tween_callback(line_2d.hide)


func set_color(new_color: Color) -> void:
	color = new_color

	if line_2d == null:
		return

	line_2d.modulate = new_color
	casting_particles.modulate = new_color
	collision_particles.modulate = new_color
	beam_particles.modulate = new_color
