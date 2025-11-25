extends CharacterBody2D

@export var speed: float = 20.0

@onready var health: HealthComponent = $HealthComponent

var target: Node2D

func _ready() -> void:
	add_to_group("enemy")

	target = get_tree().get_first_node_in_group("trawler") as Node2D
	if health != null:
		health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var dir: Vector2 = target.global_position - global_position
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()

func _on_died() -> void:
	queue_free()
