extends Area2D
class_name DamageOnHit

@export var damage: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_node("Health"):
		var hc := body.get_node("Health") as HealthComponent
		hc.apply_damage(damage)
	queue_free()
