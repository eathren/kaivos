extends Resource
class_name EnemyStats

## Stats configuration for enemy tiers

@export var tier: int = 1
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var max_health: int = 20
@export var damage_per_second: float = 10.0
@export var move_speed: float = 60.0
@export var exp_drop: int = 10
@export var gold_drop_chance: float = 0.3
@export var scrap_drop_chance: float = 0.2

