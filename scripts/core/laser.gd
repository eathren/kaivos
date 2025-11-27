extends Node2D
class_name Laser

## Refined laser system using RayCast2D and Line2D
## Based on Godot 4 laser 2D patterns

@export var max_range: float = 1000.0
@export var width: float = 10.0
@export var color: Color = Color(1.0, 0.35, 0.35, 1.0)
@export var damage_per_second: float = 20.0
@export var collision_mask: int = 16  # Wall layer by default
@export var direction: Vector2 = Vector2.DOWN  # Direction the laser points (DOWN for trawler, UP for ships)
@export var mining_delay: float = 0.0  # Set to 0 for instant deletion (trawler), 1.0 for mining delay (player ships)

@onready var raycast: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D
@onready var particles_start: GPUParticles2D = $ParticlesStart
@onready var particles_end: GPUParticles2D = $ParticlesEnd

var is_casting: bool = false
var _damage_timer: float = 0.0
var _damage_interval: float = 0.1  # Apply damage every 0.1 seconds

# Mining state
var _mining_timer: float = 0.0
var _current_mining_cell: Vector2i = Vector2i(-99999, -99999)

func _ready() -> void:
	if raycast:
		# Set target position based on direction
		raycast.target_position = direction.normalized() * max_range
		raycast.collision_mask = collision_mask
		raycast.enabled = false
	
	if line:
		line.width = width
		line.default_color = color
		line.visible = false
	
	_set_particles_enabled(false)

func _process(delta: float) -> void:
	if not is_casting:
		return
	
	_update_laser(delta)

func _update_laser(delta: float) -> void:
	if not raycast or not line:
		return
	
	# Force raycast update
	raycast.force_raycast_update()
	
	var end_point: Vector2
	if raycast.is_colliding():
		# Hit something - draw to collision point
		var collision_point := raycast.get_collision_point()
		end_point = to_local(collision_point)
		
		# Apply damage to walls (with mining delay)
		_damage_timer += delta
		if _damage_timer >= _damage_interval:
			_damage_timer = 0.0
			_apply_damage(collision_point, delta)
		
		# Update end particles
		if particles_end:
			particles_end.global_position = collision_point
			particles_end.rotation = raycast.get_collision_normal().angle()
	else:
		# No collision - reset mining timer
		_mining_timer = 0.0
		_current_mining_cell = Vector2i(-99999, -99999)
		# No collision - draw to max range
		end_point = raycast.target_position
	
	# Update line
	line.points = PackedVector2Array([Vector2.ZERO, end_point])
	line.visible = true

func _apply_damage(hit_point: Vector2, delta: float) -> void:
	# Find wall tilemap and erase walls along the laser path
	var wall := get_tree().get_first_node_in_group("wall") as TileMapLayer
	if wall == null:
		return
	
	var local_in_wall := wall.to_local(hit_point)
	var center_cell := wall.local_to_map(local_in_wall)
	
	# Check if we're mining a new cell
	if center_cell != _current_mining_cell:
		_current_mining_cell = center_cell
		_mining_timer = 0.0
	
	# Accumulate mining time
	_mining_timer += delta
	
	# Only delete after mining delay (if any)
	if _mining_timer < mining_delay:
		return
	
	# Calculate how many tiles wide the laser is (convert pixels to tiles, assuming 16x16 tiles)
	var tile_size := 16.0
	var half_width_tiles := int(ceil((width / 2.0) / tile_size))
	
	# Erase a horizontal strip of tiles centered on the hit point
	for x in range(center_cell.x - half_width_tiles, center_cell.x + half_width_tiles + 1):
		var cell := Vector2i(x, center_cell.y)
		
		# Only erase if there's actually a wall tile there
		if wall.get_cell_source_id(cell) != -1:
			# Check if it's a wall tile (not ground)
			var atlas_coord := wall.get_cell_atlas_coords(cell)
			var source_id := wall.get_cell_source_id(cell)
			
			# Get wall tile parameters from wall script
			var wall_atlas_coord := Vector2i(1, 1)  # Default
			var wall_source_id := 5  # Default
			if "wall_atlas_coord" in wall:
				wall_atlas_coord = wall.get("wall_atlas_coord")
			if "tile_source_id" in wall:
				wall_source_id = wall.get("tile_source_id")
			
			# Only erase wall tiles, not ground
			if source_id == wall_source_id and atlas_coord == wall_atlas_coord:
				wall.erase_cell(cell)
	
	# Reset mining timer after deleting
	_mining_timer = 0.0

func set_is_casting(cast: bool) -> void:
	is_casting = cast
	
	if raycast:
		raycast.enabled = cast
	
	if line:
		line.visible = cast
	
	_set_particles_enabled(cast)
	
	if not cast:
		# Reset mining state
		_mining_timer = 0.0
		_current_mining_cell = Vector2i(-99999, -99999)
		# Clear line when not casting
		if line:
			line.points = PackedVector2Array()

func _set_particles_enabled(enabled: bool) -> void:
	if particles_start:
		particles_start.emitting = enabled
	if particles_end:
		particles_end.emitting = enabled
