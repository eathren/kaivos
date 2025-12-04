extends Node

## Manages player Zeal - a momentum system that glows brighter with kills
## Max 100, decays over time when not killing

const MAX_ZEAL: int = 100
const ZEAL_PER_KILL: int = 15
const ZEAL_DECAY_RATE: float = 5.0  # Zeal lost per second
const ZEAL_DECAY_DELAY: float = 3.0  # Seconds before decay starts

var player_zeal: Dictionary = {}  # player_id -> current_zeal
var last_kill_time: Dictionary = {}  # player_id -> time of last kill

func _process(delta: float) -> void:
	# Decay zeal over time
	for player_id in player_zeal.keys():
		var time_since_kill = Time.get_ticks_msec() / 1000.0 - last_kill_time.get(player_id, 0.0)
		
		if time_since_kill > ZEAL_DECAY_DELAY:
			var decay_amount = ZEAL_DECAY_RATE * delta
			player_zeal[player_id] = maxf(0.0, player_zeal[player_id] - decay_amount)

func add_zeal(player_id: int, amount: int = ZEAL_PER_KILL) -> void:
	"""Add zeal when player gets a kill"""
	if player_id < 0:
		return
	
	if not player_id in player_zeal:
		player_zeal[player_id] = 0.0
	
	player_zeal[player_id] = minf(MAX_ZEAL, player_zeal[player_id] + amount)
	last_kill_time[player_id] = Time.get_ticks_msec() / 1000.0

func get_zeal(player_id: int) -> float:
	"""Get current zeal as 0.0 to 1.0"""
	if player_id < 0 or not player_id in player_zeal:
		return 0.0
	return player_zeal[player_id] / float(MAX_ZEAL)

func get_zeal_raw(player_id: int) -> int:
	"""Get raw zeal value (0-100)"""
	if player_id < 0 or not player_id in player_zeal:
		return 0
	return int(player_zeal[player_id])
