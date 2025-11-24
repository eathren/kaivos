extends CharacterBody2D

@export var speed: float = 60.0

var trawler: CharacterBody2D

func _ready() -> void:
	trawler = get_tree().get_first_node_in_group("trawler")
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	if trawler == null:
		return

	var dir := (trawler.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
