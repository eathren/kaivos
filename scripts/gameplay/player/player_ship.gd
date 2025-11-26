extends Node2D

## Player ship with two small lasers
## Lasers toggle on/off with interact button

signal lasers_toggled(is_on: bool)

@onready var left_laser: Laser = $LeftLaser
@onready var right_laser: Laser = $RightLaser

var lasers_enabled: bool = false

func _ready() -> void:
	# Start with lasers off
	_update_lasers()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		lasers_enabled = not lasers_enabled
		_update_lasers()
		lasers_toggled.emit(lasers_enabled)

func _update_lasers() -> void:
	if left_laser:
		left_laser.set_is_casting(lasers_enabled)
	if right_laser:
		right_laser.set_is_casting(lasers_enabled)
