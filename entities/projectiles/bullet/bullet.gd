extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var lifetime: float = 2.0
@export var pierce: int = 0  # How many enemies it can go through
@export var faction: FactionComponent.Faction = FactionComponent.Faction.PLAYER

var _age: float = 0.0
var _pierce_count: int = 0  # How many enemies we've hit so far

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Set collision mask to detect enemies (layer 1 = Enemy = 2^0 = 1)
	# Also detect EnemyHitbox (layer 6 = 2^5 = 32)
	collision_mask = 1 | 32  # Detect Enemy and EnemyHitbox layers

func _physics_process(delta: float) -> void:
	var dir: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	global_position += dir * speed * delta

	_age += delta
	if _age >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Do NOT kill the bullet if it hits something that cannot be damaged
	print("Collision detected with: ", body.name)
	var target_faction := body.get_node_or_null("FactionComponent") as FactionComponent
	if target_faction == null:
		print("  No FactionComponent found")
		return

	if not FactionComponent.is_hostile_factions(faction, target_faction.faction):
		print("  Not hostile factions")
		return

	var health := body.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		print("  Applying damage: ", damage)
		health.apply_damage(damage)
		_pierce_count += 1
		
		# Check if we've pierced enough enemies
		if _pierce_count > pierce:
			queue_free()
	else:
		print("  No HealthComponent found")
