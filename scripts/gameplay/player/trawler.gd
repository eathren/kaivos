extends CharacterBody2D

@export var forward_speed: float = 20.0
@export var accel: float = 4.0

@onready var bumper: Area2D = $FrontBumper

var blocked: bool = false

func _ready() -> void:
	add_to_group("trawler")
	bumper.area_entered.connect(_on_bumper_hit)
	bumper.area_exited.connect(_on_bumper_clear)

func _on_bumper_hit(_area: Area2D) -> void:
	blocked = true

func _on_bumper_clear(_area: Area2D) -> void:
	blocked = false

func _physics_process(delta: float) -> void:
	var target_speed := 0.0
	if not blocked:
		target_speed = -forward_speed

	var t = clamp(accel * delta, 0.0, 1.0)
	var new_speed := lerpf(velocity.y, target_speed, t)

	velocity = Vector2(0.0, new_speed)
	move_and_slide()
