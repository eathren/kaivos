extends Resource
class_name UpgradeData

## Data resource for upgrade configuration

enum UpgradeType {
	FIRE_RATE,
	DAMAGE,
	SHIP_SPEED,
	PICKUP_RANGE,
	MAX_HEALTH,
	UNLOCK_WEAPON
}

@export var upgrade_name: String = "Fire Rate"
@export var upgrade_type: UpgradeType = UpgradeType.FIRE_RATE
@export var description: String = "Increase fire rate by 10%"
@export var gold_cost: int = 100
@export var scrap_cost: int = 0
@export var max_level: int = 5
@export var value_per_level: float = 0.1
@export var icon: Texture2D = null

