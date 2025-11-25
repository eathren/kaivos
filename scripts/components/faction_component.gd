extends Node
class_name FactionComponent

enum Faction {
	PLAYER,
	ENEMY,
	NEUTRAL
}

@export var faction: Faction = Faction.ENEMY

func _ready() -> void:
	var owner_node := get_owner() as Node
	if owner_node == null:
		return

	match faction:
		Faction.PLAYER:
			owner_node.add_to_group("player")
		Faction.ENEMY:
			owner_node.add_to_group("enemy")
		Faction.NEUTRAL:
			owner_node.add_to_group("neutral")

static func is_hostile_factions(a: Faction, b: Faction) -> bool:
	if a == Faction.NEUTRAL or b == Faction.NEUTRAL:
		return false
	return a != b
	
func is_same_faction(other: FactionComponent) -> bool:
	if other == null:
		return false
	return other.faction == faction

func is_hostile_to(other: FactionComponent) -> bool:
	if other == null:
		return false
	if faction == Faction.NEUTRAL or other.faction == Faction.NEUTRAL:
		return false
	return faction != other.faction
