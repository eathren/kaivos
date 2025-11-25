extends Node

## Main scene script - Handles initial setup and can start the run

func _ready() -> void:
	print("Running game")
	# Wait for RunManager to be ready
	await get_tree().process_frame
	
	# Auto-start a run if RunManager is available
	if RunManager != null:
		# Start a new run with a random seed
		RunManager.start_run(randi())
	else:
		push_error("Main: RunManager not found")

func _unhandled_input(event: InputEvent) -> void:
	# Debug: Press R to regenerate the map
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		if RunManager != null:
			print("Main: Regenerating map...")
			RunManager.start_run(randi())
