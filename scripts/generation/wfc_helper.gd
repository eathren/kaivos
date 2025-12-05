extends Node

## Helper for converting WFC symbols to TileMap tiles

# Map symbols to tile coordinates
# Using your actual tileset coordinates from wall.gd
const SYMBOL_TO_TILE := {
	# Mine symbols - Core tiles (MAPPED TO YOUR ACTUAL TILESET)
	"ROCK": { "source_id": 0, "atlas": Vector2i(2, 1) },        # Wall center
	"EMPTY": { "source_id": 0, "atlas": Vector2i(1, 5) },       # Ground/floor
	"WALL": { "source_id": 0, "atlas": Vector2i(2, 1) },        # Wall center
	"ROOM_FLOOR": { "source_id": 0, "atlas": Vector2i(1, 5) },  # Ground
	"CORRIDOR": { "source_id": 0, "atlas": Vector2i(1, 5) },    # Ground
	
	# Mine features - TODO: Add these tiles to your tileset
	"ORE": { "source_id": 0, "atlas": Vector2i(1, 0) },         # TODO: Add ore tile here
	"LAVA": { "source_id": 0, "atlas": Vector2i(2, 0) },        # TODO: Add lava tile here
	"DOOR": { "source_id": 0, "atlas": Vector2i(3, 0) },        # TODO: Add door tile here
	"TREASURE": { "source_id": 0, "atlas": Vector2i(3, 1) },    # Use wall variant for now
	"PILLAR": { "source_id": 0, "atlas": Vector2i(3, 1) },      # Use wall variant for now
	
	# Town/surface symbols - TODO: Add town tileset when needed
	"GRASS": { "source_id": 2, "atlas": Vector2i(0, 1) },       # Ground tileset
	"DIRT": { "source_id": 2, "atlas": Vector2i(0, 0) },        # Ground tileset
	"STONE_PATH": { "source_id": 0, "atlas": Vector2i(1, 5) },  # Use ground for now
	"WATER": { "source_id": 0, "atlas": Vector2i(2, 0) },       # TODO: Add water tile
	"TREE": { "source_id": 0, "atlas": Vector2i(1, 0) },        # TODO: Add tree tile
	"ROCK_SMALL": { "source_id": 0, "atlas": Vector2i(1, 0) },  # TODO: Add rock tile
	"WALL_STONE": { "source_id": 0, "atlas": Vector2i(2, 1) },  # Use wall center
	"WALL_WOOD": { "source_id": 0, "atlas": Vector2i(2, 1) },   # Use wall center
	"FLOOR_STONE": { "source_id": 0, "atlas": Vector2i(1, 5) }, # Use ground
	"FLOOR_WOOD": { "source_id": 0, "atlas": Vector2i(1, 5) },  # Use ground
	"WINDOW": { "source_id": 0, "atlas": Vector2i(3, 0) },      # TODO: Add window tile
	"ROOF": { "source_id": 0, "atlas": Vector2i(3, 0) },        # TODO: Add roof tile
	"BARREL": { "source_id": 0, "atlas": Vector2i(1, 0) },      # TODO: Add barrel tile
	"CRATE": { "source_id": 0, "atlas": Vector2i(1, 0) },       # TODO: Add crate tile
	
	# Dungeon symbols - Use mine tiles for now
	"VOID": { "source_id": 0, "atlas": Vector2i(2, 1) },        # Use wall (impassable)
	"WALL_DUNGEON": { "source_id": 0, "atlas": Vector2i(2, 1) },# Use wall center
	"FLOOR": { "source_id": 0, "atlas": Vector2i(1, 5) },       # Use ground
	"STAIRS_UP": { "source_id": 0, "atlas": Vector2i(1, 5) },   # TODO: Add stairs tile
	"STAIRS_DOWN": { "source_id": 0, "atlas": Vector2i(1, 5) }, # TODO: Add stairs tile
	"ALTAR": { "source_id": 0, "atlas": Vector2i(3, 1) },       # Use wall variant
	"CHEST": { "source_id": 0, "atlas": Vector2i(1, 0) },       # TODO: Add chest tile
	"TORCH": { "source_id": 0, "atlas": Vector2i(1, 0) },       # TODO: Add torch tile
	"TRAP": { "source_id": 0, "atlas": Vector2i(1, 5) },        # Use ground (invisible)
	"WATER_DEEP": { "source_id": 0, "atlas": Vector2i(2, 0) },  # TODO: Add water tile
	"BRIDGE": { "source_id": 0, "atlas": Vector2i(1, 5) }       # Use ground
}

static func seed_from_string(s: String) -> int:
	"""Convert string to deterministic seed"""
	var h = hash(s)
	return int(h & 0x7fffffff)

static func chunk_seed(global_seed: String, cx: int, cy: int) -> int:
	"""Generate deterministic seed for a chunk"""
	return seed_from_string("%s_%d_%d" % [global_seed, cx, cy])

static func paint_to_tilemap(tilemap: TileMap, symbol_grid: Array, layer: int = 0) -> void:
	"""Paint WFC symbol grid to TileMap"""
	if symbol_grid.is_empty():
		return
	
	var h := symbol_grid.size()
	var w = symbol_grid[0].size()
	
	for y in range(h):
		for x in range(w):
			var sym: String = symbol_grid[y][x]
			
			if sym == "UNKNOWN":
				continue
			
			if sym not in SYMBOL_TO_TILE:
				push_warning("Unknown symbol for tile mapping: " + sym)
				continue
			
			var info = SYMBOL_TO_TILE[sym]
			tilemap.set_cell(
				layer,
				Vector2i(x, y),
				info.source_id,
				info.atlas
			)

static func generate_chunk(rules_path: String, chunk_size: int, seed_value: int) -> Array:
	"""Generate a chunk of terrain using WFC"""
	var wfc := Wfc.new()
	
	if not wfc.load_rules(rules_path):
		push_error("[WFC] Failed to load rules from: " + rules_path)
		return []
	
	print("[WFC] Initializing %dx%d grid with seed %d" % [chunk_size, chunk_size, seed_value])
	wfc.init_grid(chunk_size, chunk_size, seed_value)
	
	if not wfc.run_to_completion():
		push_error("[WFC] Generation failed (contradiction) for seed %d" % seed_value)
		return []
	
	return wfc.get_symbol_grid()
