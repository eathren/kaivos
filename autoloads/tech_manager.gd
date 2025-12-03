extends Node

## Manages tech items and their stacks for each player

signal item_acquired(player_id: int, item: TechItem, stack_count: int)

var unlocked := {}

# Player item stacks: player_id -> { item_id -> stack_count }
var player_items: Dictionary = {}

# Item pool - preload all items
var item_pool: Array[TechItem] = []

# Banish system: player_id -> { item_id -> true }
var banished_items: Dictionary = {}

# Banish uses remaining: player_id -> int
var banish_uses: Dictionary = {}

func _ready() -> void:
	_load_item_pool()

func _load_item_pool() -> void:
	"""Load all tech items from resources"""
	item_pool.clear()
	
	# Load items
	var neon_halo = load("res://resources/data/items/neon_halo_cartridge.tres") as TechItem
	var gilded_barrel = load("res://resources/data/items/gilded_barrel_shroud.tres") as TechItem
	var saintbreaker = load("res://resources/data/items/saintbreaker_rounds.tres") as TechItem
	
	if neon_halo:
		item_pool.append(neon_halo)
	if gilded_barrel:
		item_pool.append(gilded_barrel)
	if saintbreaker:
		item_pool.append(saintbreaker)
	
	print("TechManager: Loaded %d items" % item_pool.size())

func has_tech(t: StringName) -> bool:
	return unlocked.get(t, false)
	
func unlock(t: StringName) -> void:
	unlocked[t] = true

## Get player's item stack count
func get_item_stack(player_id: int, item_id: String) -> int:
	if not player_items.has(player_id):
		return 0
	return player_items[player_id].get(item_id, 0)

## Add item stack for player
func add_item_stack(player_id: int, item: TechItem) -> int:
	if not player_items.has(player_id):
		player_items[player_id] = {}
	
	var current_stack = player_items[player_id].get(item.id, 0)
	
	# Check max stacks
	if item.max_stacks > 0 and current_stack >= item.max_stacks:
		print("TechManager: Player %d already has max stacks of %s" % [player_id, item.display_name])
		return current_stack
	
	current_stack += 1
	player_items[player_id][item.id] = current_stack
	
	item_acquired.emit(player_id, item, current_stack)
	print("TechManager: Player %d acquired %s (stack %d)" % [player_id, item.display_name, current_stack])
	
	return current_stack

## Get all items for a player
func get_player_items(player_id: int) -> Dictionary:
	return player_items.get(player_id, {})

## Generate item choices for level up (always returns exactly count items)
func generate_item_choices(player_id: int, count: int = 4, level: int = 1) -> Array[TechItem]:
	var choices: Array[TechItem] = []
	
	# Get available items (not at max stacks and not banished)
	var available_items = item_pool.duplicate()
	available_items = available_items.filter(func(item):
		var stack = get_item_stack(player_id, item.id)
		var not_maxed = item.max_stacks < 0 or stack < item.max_stacks
		var not_banished = not is_item_banished(player_id, item)
		return not_maxed and not_banished
	)
	
	# If no items available, return empty (shouldn't happen with proper pool)
	if available_items.is_empty():
		push_warning("TechManager: No available items for player %d!" % player_id)
		return choices
	
	# Get luck from GameState
	var luck = GameState.get_blessed_luck() if GameState else 0.0
	
	# Generate each choice with individual rarity roll
	for i in range(count):
		# Determine rarity for this choice based on level and luck
		var rarity = get_level_up_rarity(level, luck)
		
		# Filter items by this rarity
		var rarity_items = available_items.filter(func(item): return item.rarity == rarity)
		
		# If no items of this rarity, fall back to all available
		if rarity_items.is_empty():
			rarity_items = available_items
		
		# Pick random item (with replacement - can appear multiple times)
		var random_item = rarity_items[randi() % rarity_items.size()]
		choices.append(random_item)
	
	return choices

## Determine rarity for level up based on level and luck
func get_level_up_rarity(level: int, luck: float = 0.0) -> TechItem.Rarity:
	# Base roll with luck modifier (each point of luck shifts towards higher tiers)
	var roll = randf()
	# Apply luck bonus - each 1.0 luck increases roll by 0.1 (capped)
	roll = clamp(roll + (luck * 0.1), 0.0, 1.0)
	
	if level < 5:
		# Early game: mostly common
		if roll < 0.7:
			return TechItem.Rarity.COMMON
		else:
			return TechItem.Rarity.UNCOMMON
	elif level < 10:
		# Mid game: mix of common and uncommon
		if roll < 0.4:
			return TechItem.Rarity.COMMON
		elif roll < 0.85:
			return TechItem.Rarity.UNCOMMON
		else:
			return TechItem.Rarity.RARE
	else:
		# Late game: higher rarities
		if roll < 0.2:
			return TechItem.Rarity.COMMON
		elif roll < 0.5:
			return TechItem.Rarity.UNCOMMON
		elif roll < 0.8:
			return TechItem.Rarity.RARE
		elif roll < 0.95:
			return TechItem.Rarity.EPIC
		else:
			return TechItem.Rarity.LEGENDARY
	
	return TechItem.Rarity.COMMON

## Reset player items (for new run)
func reset_player_items(player_id: int = -1) -> void:
	if player_id >= 0:
		player_items.erase(player_id)
		banished_items.erase(player_id)
		banish_uses[player_id] = 3  # Start with 3 banish uses
	else:
		player_items.clear()
		banished_items.clear()
		banish_uses.clear()
	print("TechManager: Reset items for player %d" % player_id)

## Check if player has banish uses remaining
func get_banish_uses(player_id: int) -> int:
	return banish_uses.get(player_id, 3)

## Banish an item (prevent it from appearing again)
func banish_item(player_id: int, item: TechItem) -> bool:
	if get_banish_uses(player_id) <= 0:
		return false
	
	if not banished_items.has(player_id):
		banished_items[player_id] = {}
	
	banished_items[player_id][item.id] = true
	banish_uses[player_id] = get_banish_uses(player_id) - 1
	
	print("TechManager: Player %d banished %s (%d uses left)" % [player_id, item.display_name, get_banish_uses(player_id)])
	return true

## Check if an item is banished for a player
func is_item_banished(player_id: int, item: TechItem) -> bool:
	if not banished_items.has(player_id):
		return false
	return banished_items[player_id].get(item.id, false)
