extends Resource
class_name WeaponStats

## Stats configuration for weapons

@export var weapon_id: int = 0
@export var weapon_name: String = "Basic Gun"
@export var fire_rate: float = 0.2
@export var damage: int = 10
@export var projectile_speed: float = 600.0
@export var spread_degrees: float = 5.0
@export var bullets_per_shot: int = 1
@export var pierce_count: int = 0  # How many enemies bullet can pierce

