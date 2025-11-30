extends Node2D

@export var is_drilling: bool = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_drilling = GameState.is_drilling
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
