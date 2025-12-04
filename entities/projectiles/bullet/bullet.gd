extends Area2D

@export var speed: float = 600.0
@export var base_damage: int = 10
@export var damage_variance: float = 0.2  # ±20% damage range
@export var lifetime: float = 2.0
@export var pierce: int = 0  # How many enemies it can go through
@export var faction: FactionComponent.Faction = FactionComponent.Faction.PLAYER
@export var crit_chance: float = 0.0  # 0.0 to 1.0
@export var crit_multiplier: float = 2.0
@export var megacrit_chance: float = 0.0  # 0.0 to 1.0
@export var megacrit_multiplier: float = 4.0
@export var elite_damage_bonus: float = 0.0  # Bonus damage vs elites/bosses (0.15 = +15%)

var _age: float = 0.0
var _pierce_count: int = 0  # How many enemies we've hit so far
var _is_crit: bool = false
var _is_megacrit: bool = false
var _rolled_damage: int = 0  # Actual damage rolled for this bullet
var shooter_id: int = -1  # Who fired this bullet (for kill credit)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Set collision mask to detect enemies (layer 1 = Enemy = 2^0 = 1)
	# Also detect EnemyHitbox (layer 6 = 2^5 = 32)
	collision_mask = 1 | 32  # Detect Enemy and EnemyHitbox layers
	
	# Roll damage with luck weighting
	if GameState and GameState.has_method("roll_damage_in_range"):
		_rolled_damage = int(GameState.roll_damage_in_range(base_damage, damage_variance))
	else:
		_rolled_damage = base_damage
	
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
		var final_damage = _rolled_damage
		if _is_megacrit:
			final_damage = int(_rolled_damage * megacrit_multiplier)
		elif _is_crit:
			final_damage = int(_rolled_damage * crit_multiplier)
		
		# Apply elite/boss damage bonus if target is elite or boss
		if elite_damage_bonus > 0.0 and body.has_method("get") and (body.get("is_elite") or body.get("is_boss")):
			final_damage = int(final_damage * (1.0 + elite_damage_bonus))
		
		print("  Applying damage: ", final_damage, " (base roll: ", _rolled_damage, ", crit: ", _is_crit, ", megacrit: ", _is_megacrit, ")")
		health.apply_damage(final_damage, _is_crit, _is_megacrit, shooter_id)
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
