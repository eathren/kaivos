extends Node
class_name RunDifficulty

## Tracks run difficulty based on time and progress
## Enemies query this once at spawn to bake in their stats

var time_elapsed: float = 0.0
var depth_traveled: float = 0.0  # Distance into the mine

func _process(delta: float) -> void:
	time_elapsed += delta

func get_enemy_level() -> int:
	"""Calculate enemy level based on time and depth"""
	var time_factor := time_elapsed / 60.0  # Minutes elapsed
	var depth_factor := depth_traveled * 0.001  # Tiles or units traveled
	return 1 + int(floor(time_factor + depth_factor))

func add_depth(amount: float) -> void:
	"""Track progress into the mine"""
	depth_traveled += amount

func reset() -> void:
	"""Reset difficulty for new run"""
	time_elapsed = 0.0
	depth_traveled = 0.0
