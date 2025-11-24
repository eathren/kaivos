extends CharacterBody2D

@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 0.5

var base_position: Vector2

func _ready() -> void:
	add_to_group("trawler")
	base_position = global_position

func _physics_process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var offset := sin(t * bob_speed) * bob_amplitude
	global_position = Vector2(base_position.x, base_position.y + offset)
