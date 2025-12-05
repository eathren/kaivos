# Tileset Coordinate Mapping Guide

## Your Current Tileset Layout

Based on `wall.gd`, your current tiles are:

```
Row 0: [?, ?, ?, ...]
Row 1: [?, ?, wall_center, ...]
Row 2: [?, wall_edge_1, wall_edge_2, wall_edge_3, ...]
Row 3: [?, wall_face_1, wall_face_2, wall_face_3, ...]
Row 4: [?, ?, ?, ...]
Row 5: [?, ground, ?, ...]
```

**Current Coordinates:**
- Ground/Floor: `Vector2i(1, 5)` - empty walkable space
- Wall Center: `Vector2i(2, 1)` - solid wall interior
- Wall Edge (top lip): `Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)` - variants
- Wall Face (vertical): `Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)` - variants

## How Walls Work in Your System

Your current system uses a **3-tile wall system** (not full autotiling):

1. **Wall Center** `Vector2i(2, 1)` - Used for interior wall blocks (surrounded by other walls)
2. **Wall Edge** `Vector2i(1-3, 2)` - Used for top edge of walls (nothing above, wall below)
3. **Wall Face** `Vector2i(1-3, 3)` - Used for bottom edge (wall above, nothing below) - this is the "visible face"

This is simpler than full corner/edge autotiling and works well for top-down mines.

## For WFC Symbols, Map Like This:

### Basic Terrain (what you have now):
```gdscript
"WALL": { "source_id": 0, "atlas": Vector2i(2, 1) }       # Wall center
"ROCK": { "source_id": 0, "atlas": Vector2i(2, 1) }       # Same as wall
"EMPTY": { "source_id": 0, "atlas": Vector2i(1, 5) }      # Ground/floor
"ROOM_FLOOR": { "source_id": 0, "atlas": Vector2i(1, 5) } # Same as ground
"CORRIDOR": { "source_id": 0, "atlas": Vector2i(1, 5) }   # Same as ground
```

### Additional Tiles (you'll need to add these to your tileset):

If you want WFC features to be visible, add tiles to your tileset and map them:

```gdscript
# Ores - add at row 6
"ORE": { "source_id": 0, "atlas": Vector2i(0, 6) }

# Hazards - add at row 6
"LAVA": { "source_id": 0, "atlas": Vector2i(1, 6) }

# Structures - add at row 7
"DOOR": { "source_id": 0, "atlas": Vector2i(0, 7) }
"PILLAR": { "source_id": 0, "atlas": Vector2i(1, 7) }
"TREASURE": { "source_id": 0, "atlas": Vector2i(2, 7) }
```

## How to Find Coordinates in Godot Editor

1. **Open your TileSet resource** in Godot
2. **Select the TileSetAtlasSource** (the one with your wall tiles)
3. **Hover over tiles** - Godot shows coordinates in bottom-left as `(x, y)`
4. **Count from (0, 0)** at top-left

Example with 16x16 tiles in a 256px wide image:
```
Row 0: (0,0) (1,0) (2,0) (3,0) ... (15,0)
Row 1: (0,1) (1,1) (2,1) (3,1) ... (15,1)
Row 2: (0,2) (1,2) (2,2) (3,2) ... (15,2)
...
```

## Full Corner/Edge Autotiling (Advanced)

If you want **proper autotiling with corners**, you need a **47-tile blob** or **16-tile minimal** set:

### 16-Tile Minimal (Bitmask):
```
0000 = empty
0001 = N only
0010 = E only  
0100 = S only
1000 = W only
0011 = NE corner
0110 = SE corner
1100 = SW corner
1001 = NW corner
0101 = N+S (vertical)
1010 = E+W (horizontal)
0111 = T junction (no W)
1011 = T junction (no E)
1101 = T junction (no S)
1110 = T junction (no N)
1111 = all sides (center)
```

But your **current 3-tile system is simpler and works fine** for a mine with top-down view!

## Recommended Approach for Your Game

**Keep it simple:** Use your existing 3-tile wall system. Map WFC symbols like this:

### In `wfc_helper.gd` SYMBOL_TO_TILE:

```gdscript
const SYMBOL_TO_TILE := {
    # Walls and solid blocks - all map to wall center
    "ROCK": { "source_id": 0, "atlas": Vector2i(2, 1) },
    "WALL": { "source_id": 0, "atlas": Vector2i(2, 1) },
    "WALL_DUNGEON": { "source_id": 0, "atlas": Vector2i(2, 1) },
    
    # Floors and walkable space - all map to ground
    "EMPTY": { "source_id": 0, "atlas": Vector2i(1, 5) },
    "ROOM_FLOOR": { "source_id": 0, "atlas": Vector2i(1, 5) },
    "CORRIDOR": { "source_id": 0, "atlas": Vector2i(1, 5) },
    "FLOOR": { "source_id": 0, "atlas": Vector2i(1, 5) },
    
    # Features - add new tiles to your tileset for these
    "ORE": { "source_id": 0, "atlas": Vector2i(4, 5) },      # Pick an empty slot
    "LAVA": { "source_id": 0, "atlas": Vector2i(5, 5) },     # Pick an empty slot
    "DOOR": { "source_id": 0, "atlas": Vector2i(6, 5) },     # Pick an empty slot
    "TREASURE": { "source_id": 0, "atlas": Vector2i(7, 5) }, # Pick an empty slot
    "PILLAR": { "source_id": 0, "atlas": Vector2i(8, 5) },   # Pick an empty slot
}
```

The **edge detection in `_apply_tiles()`** handles wall faces/edges automatically - you don't need to map those in WFC!

## Why Your Wall System Works

Your `_apply_tiles()` function already does smart wall edge detection:
- Checks neighbors above/below each wall cell
- No neighbor below? Use **wall_face** (visible bottom edge)
- No neighbor above? Use **wall_edge** (top lip)
- Has both? Use **wall_center** (interior)

This means WFC just says "this is a wall cell" and your existing code makes it look correct!

## Next Steps

1. Open your tileset in Godot editor
2. Hover over tiles to find coordinates (shown in bottom-left)
3. Update the coordinates in my code snippet above
4. Optionally: Add ore/lava/feature tiles to empty slots in your tileset
5. Use those coordinates in `SYMBOL_TO_TILE`

Want me to update `wfc_helper.gd` with the correct coordinates once you tell me what tiles you have?
