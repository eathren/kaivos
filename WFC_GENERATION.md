# Wave Function Collapse (WFC) Generation System

## Overview

Clean WFC implementation that generates terrain from abstract symbols, then maps them to tiles.

## Key Principles

1. **WFC generates SYMBOLS, not tiles** - "ROCK", "EMPTY", "ORE", etc.
2. **Rules live in JSON**, not in TileSets
3. **Tile mapping is separate** - convert symbols to tiles after generation
4. **Deterministic from seed** - same seed = same world

## Files

- `scripts/generation/wfc.gd` - Core WFC algorithm
- `scripts/generation/wfc_helper.gd` - Helper utilities and tile mapping
- `data/wfc/mine_rules.json` - Rules for mine generation
- `systems/generation/wfc_test.tscn` - Test scene

## Usage

### Basic Generation

```gdscript
var wfc := Wfc.new()
wfc.load_rules("res://data/wfc/mine_rules.json")
wfc.init_grid(32, 32, 12345)  # width, height, seed
wfc.run_to_completion()
var symbol_grid = wfc.get_symbol_grid()
```

### With Helper

```gdscript
var seed = WfcHelper.seed_from_string("my-world-seed")
var symbol_grid = WfcHelper.generate_chunk(
    "res://data/wfc/mine_rules.json",
    32,  # chunk size
    seed
)
WfcHelper.paint_to_tilemap($TileMap, symbol_grid, 0)
```

### Chunked Generation

```gdscript
func generate_chunk(cx: int, cy: int) -> void:
    var seed = WfcHelper.chunk_seed("world-seed", cx, cy)
    var symbols = WfcHelper.generate_chunk("res://data/wfc/mine_rules.json", 16, seed)
    WfcHelper.paint_to_tilemap($TileMap, symbols, 0)
```

## Rule File Format

```json
{
  "symbols": ["ROCK", "EMPTY", "ORE", "LAVA", "WALL"],
  "weights": {
    "ROCK": 5,    // Higher = more common
    "EMPTY": 3,
    "ORE": 1
  },
  "neighbors": {
    "ROCK": {
      "N": ["ROCK", "EMPTY"],  // Valid neighbors to the North
      "E": ["ROCK", "EMPTY"],
      "S": ["ROCK", "EMPTY"],
      "W": ["ROCK", "EMPTY"]
    }
  }
}
```

## Symbol to Tile Mapping

Edit `wfc_helper.gd` SYMBOL_TO_TILE dictionary:

```gdscript
const SYMBOL_TO_TILE := {
    "ROCK": { "source_id": 0, "atlas": Vector2i(0, 0) },
    "EMPTY": { "source_id": 0, "atlas": Vector2i(1, 0) },
    "ORE": { "source_id": 0, "atlas": Vector2i(2, 0) }
}
```

For terrain/autotile support, map to terrain indices instead.

## Multiple Rule Sets

Create different JSON files for different biomes:

- `mine_rules.json` - Underground caverns
- `surface_rules.json` - Overworld
- `town_rules.json` - Villages/structures

Load the appropriate one based on context.

## Multiplayer Sync

### Option A: Host generates, clients download
- Host runs WFC, saves result
- On client join, send full map data
- Then sync only tile changes

### Option B: Everyone generates from seed
- Host picks seed string
- Clients run identical WFC with same seed
- Requires exact same rules/code version
- Lighter bandwidth once stable

For now, **use Option A** - it's more forgiving during development.

## Testing

Run `systems/generation/wfc_test.tscn`:
- Press SPACE to regenerate
- WASD to move camera
- Check console for generation logs

## Next Steps

1. Test generation - run wfc_test.tscn
2. Adjust mine_rules.json weights/neighbors to taste
3. Update SYMBOL_TO_TILE to match your tileset
4. Create additional rule files (surface, town, etc.)
5. Integrate into your level generation system
6. Add chunked generation around trawler

## TileSet Questions Answered

**Q: Do I make 4 tilesets or one?**
A: Doesn't matter. WFC only sees symbols. Use whatever keeps your editor sane.

**Q: Do I paint terrains?**
A: If you want autotiling, yes. Map symbols to terrain indices, use set_cells_terrain_connect.

**Q: Where do rules go?**
A: JSON files in data/wfc/, NOT in TileSets.

## Algorithm Notes

The WFC implementation:
- Uses entropy-based cell selection (lowest possibilities first)
- Weighted random collapse based on symbol weights
- Constraint propagation to neighbors
- Detects contradictions (will restart on failure)
- Fully deterministic from seed

No backtracking yet - if contradiction occurs, it returns false and you'd regenerate with a different seed or tweak rules.
