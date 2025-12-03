extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var lifetime: float = 2.0
@export var pierce: int = 0  # How many enemies it can go through
@export var faction: FactionComponent.Faction = FactionComponent.Faction.PLAYER
@export var crit_chance: float = 0.0  # 0.0 to 1.0
@export var crit_multiplier: float = 2.0
@export var megacrit_chance: float = 0.0  # 0.0 to 1.0
@export var megacrit_multiplier: float = 4.0

var _age: float = 0.0
var _pierce_count: int = 0  # How many enemies we've hit so far
var _is_crit: bool = false
var _is_megacrit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Set collision mask to detect enemies (layer 1 = Enemy = 2^0 = 1)
	# Also detect EnemyHitbox (layer 6 = 2^5 = 32)
	collision_mask = 1 | 32  # Detect Enemy and EnemyHitbox layers
	
	# Roll for crit on creation
	_roll_crit()

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
		# Calculate final damage with crit multiplier
		var final_damage = damage
		if _is_megacrit:
			final_damage = int(damage * megacrit_multiplier)
		elif _is_crit:
			final_damage = int(damage * crit_multiplier)
		
		print("  Applying damage: ", final_damage, " (crit: ", _is_crit, ", megacrit: ", _is_megacrit, ")")
		health.apply_damage(final_damage, _is_crit, _is_megacrit)
		_pierce_count += 1
		
		# Check if we've pierced enough enemies
		if _pierce_count > pierce:
			queue_free()
	else:
		print("  No HealthComponent found")

func _roll_crit() -> void:
	"""Roll for critical hit on bullet creation"""
	# Check megacrit first (rarer)
	if randf() < megacrit_chance:
		_is_megacrit = true
		_is_crit = false
		# Optional: Make megacrit bullets visually distinct
		modulate = Color(1.0, 0.84, 0.0)  # Gold tint
		scale *= 1.2
	# Then check regular crit
	elif randf() < crit_chance:
		_is_crit = true
		_is_megacrit = false
		# Optional: Make crit bullets visually distinct
		modulate = Color(1.0, 0.3, 0.3)  # Red tint
		scale *= 1.1
