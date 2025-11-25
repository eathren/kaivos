extends Node2D

@export var range: float = 400.0
@export var turn_speed_deg: float = 360.0
@export var fire_interval: float = 0.3
@export var bullet_scene: PackedScene
@export var bullet_faction: FactionComponent.Faction = FactionComponent.Faction.PLAYER

@onready var muzzle: Marker2D = $Muzzle

var _cooldown: float = 0.0
var _target: Node2D = null

func _process(delta: float) -> void:
	_update_target()
	_aim(delta)
	_shoot_if_ready(delta)

func _update_target() -> void:
	if _target != null:
		if not is_instance_valid(_target):
			_target = null
		elif global_position.distance_to(_target.global_position) > range:
			_target = null

	if _target != null:
		return

	var enemies := get_tree().get_nodes_in_group("enemy")
	var best: Node2D = null
	var best_dist_sq: float = range * range

	for e in enemies:
		if not (e is Node2D):
			continue
		var d_sq: float = global_position.distance_squared_to(e.global_position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best = e

	_target = best

func _aim(delta: float) -> void:
	if _target == null:
		return

	var desired: float = ( _target.global_position - global_position ).angle()
	var current: float = rotation
	var diff: float = wrapf(desired - current, -PI, PI)
	var max_step: float = deg_to_rad(turn_speed_deg) * delta
	diff = clamp(diff, -max_step, max_step)
	rotation = current + diff

func _shoot_if_ready(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0 or _target == null:
		return

	_cooldown = fire_interval
	_spawn_bullet()

func _spawn_bullet() -> void:
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate() 
	if bullet == null:
		push_error("Turret: bullet_scene is not a Bullet")
		return

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation
	bullet.faction = bullet_faction
