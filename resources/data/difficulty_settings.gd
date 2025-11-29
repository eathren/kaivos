extends Resource
class_name DifficultySettings

## Global difficulty and progression settings

@export var base_enemy_health_per_level: float = 5.0  # +5 HP per player level
@export var base_enemy_damage_per_level: float = 2.0  # +2 DPS per player level
@export var base_enemy_speed_per_level: float = 5.0   # +5 speed per player level
@export var spawn_rate_per_level: float = 1.1  # 10% more spawns per level
@export var elite_spawn_chance_per_level: float = 0.05  # +5% elite chance per level
@export var boss_spawn_depth: int = 500  # Every X tiles, spawn a boss

func get_enemy_health_for_level(base_health: int, player_level: int) -> int:
	return int(base_health + (base_enemy_health_per_level * (player_level - 1)))

func get_enemy_damage_for_level(base_damage: float, player_level: int) -> float:
	return base_damage + (base_enemy_damage_per_level * (player_level - 1))

func get_enemy_speed_for_level(base_speed: float, player_level: int) -> float:
	return base_speed + (base_enemy_speed_per_level * (player_level - 1))

func get_spawn_rate_for_level(player_level: int) -> float:
	return pow(spawn_rate_per_level, player_level - 1)

