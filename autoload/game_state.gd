extends Node

@export var base_scroll_speed: float = 40.0
@export var base_laser_dps: float = 20.0
@export var base_enemy_speed: float = 60.0
@export var base_trawler_speed: float = 5.0

# how many tiles wide we mine in front of the ship
@export var base_mine_width_tiles: int = 8

var scroll_multiplier: float = 1.0
var laser_multiplier: float = 1.0
var enemy_speed_multiplier: float = 1.0
var trawler_speed_multiplier: float = 1.0
var mine_width_multiplier: float = 1.0
var spawn_rate_multiplier: float = 200.0

# Save/load system
var save_data: Dictionary = {}
const SAVE_FILE_PATH: String = "user://savegame.save"  

func get_scroll_speed() -> float:
	return base_scroll_speed * scroll_multiplier

func get_laser_dps() -> float:
	return base_laser_dps * laser_multiplier

func get_enemy_speed() -> float:
	return base_enemy_speed * enemy_speed_multiplier

func get_trawler_speed() -> float:
	return base_trawler_speed * trawler_speed_multiplier

func get_mine_width_tiles() -> int:
	return int(round(base_mine_width_tiles * mine_width_multiplier))

func get_spawn_rate_multiplier() -> float:
	return spawn_rate_multiplier

## Save game state to file
func save_game() -> bool:
	if RunManager == null:
		push_warning("GameState: RunManager not available for saving")
		return false
	
	# Collect save data
	if RunManager == null:
		push_warning("GameState: RunManager not available for saving")
		return false
	
	save_data = {
		"level": RunManager.current_level_num,
		"level_start_time": RunManager.level_start_time,
		"seed": RunManager.current_seed,
		"game_state": {
			"scroll_multiplier": scroll_multiplier,
			"laser_multiplier": laser_multiplier,
			"enemy_speed_multiplier": enemy_speed_multiplier,
			"trawler_speed_multiplier": trawler_speed_multiplier,
			"mine_width_multiplier": mine_width_multiplier,
			"spawn_rate_multiplier": spawn_rate_multiplier
		}
	}
	
	# Save to file
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: Failed to open save file for writing")
		return false
	
	var json_string := JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("GameState: Game saved successfully")
	return true

## Load game state from file
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		push_warning("GameState: No save file found")
		return false
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameState: Failed to open save file for reading")
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("GameState: Failed to parse save file JSON")
		return false
	
	save_data = json.data as Dictionary
	
	# Restore game state
	if save_data.has("game_state"):
		var gs := save_data["game_state"] as Dictionary
		scroll_multiplier = gs.get("scroll_multiplier", 1.0)
		laser_multiplier = gs.get("laser_multiplier", 1.0)
		enemy_speed_multiplier = gs.get("enemy_speed_multiplier", 1.0)
		trawler_speed_multiplier = gs.get("trawler_speed_multiplier", 1.0)
		mine_width_multiplier = gs.get("mine_width_multiplier", 1.0)
		spawn_rate_multiplier = gs.get("spawn_rate_multiplier", 200.0)
	
	# Restore level state
	if RunManager != null and save_data.has("level"):
		var level := save_data.get("level", 1) as int
		var start_time := save_data.get("level_start_time", 0.0) as float
		var seed_val := save_data.get("seed", 0) as int
		
		RunManager.current_level_num = level
		RunManager.level_start_time = start_time
		RunManager.current_seed = seed_val
	
	print("GameState: Game loaded successfully")
	return true

## Check if save file exists
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

## Delete save file
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE_PATH))
		print("GameState: Save file deleted")
