# Structured WFC Generation

## Overview

The mine generator now uses a **two-phase approach** for smarter, more controlled world generation:

### Phase 1: Structure Planning
- Generates high-level layout (rooms, corridors, doors)
- Creates 10 vertical sections down the mine shaft
- Places 2-4 rooms per section with variety
- Connects rooms with L-shaped corridors
- Places doors at room-corridor junctions

### Phase 2: WFC Decoration
- Fills in details around the planned structure
- Respects pre-defined cells (rooms stay rooms, corridors stay corridors)
- Decorates undefined areas with ore, lava, enemies, etc.

## Configuration

In `mine_generator.gd`:

```gdscript
# Toggle structure planning on/off
var use_structure_planning: bool = true  # Set to false for pure WFC

# Adjust chunk size for performance
var chunk_size: int = 16  # Smaller = faster, but less coherent WFC
```

In `structure_planner.gd`:

```gdscript
# Adjust room generation
var vertical_sections = 10  # More = tighter room spacing
var rooms_in_section = rng.randi_range(2, 4)  # Rooms per section
var room_width = rng.randi_range(8, 16)  # Room size variation
var room_height = rng.randi_range(6, 12)

# Adjust room types
if rng.randf() < 0.1:  # 10% chance for treasure rooms
    room_type = "treasure"
```

In `mine_rules.json`:

```json
"weights": {
  "ROOM_FLOOR": 3,  // Higher = more room tiles in undefined areas
  "CORRIDOR": 4,    // Higher = more corridors
  "TREASURE": 0.5,  // Lower = rarer
  "ORE": 2          // Adjust resource density
}
```

## How It Works

1. **Structure Planner** divides the mine into vertical sections
2. Each section gets 2-4 randomly sized rooms (8-16 tiles wide, 6-12 tiles tall)
3. Rooms are connected by L-shaped corridors (horizontal → vertical)
4. Doors placed at room-corridor junctions
5. Walls automatically placed around rooms and corridors
6. **WFC fills** undefined areas with terrain details (ore veins, lava pools, etc.)

## Room Types

Currently supported:
- **Normal**: Standard rooms (90% chance)
- **Treasure**: Special loot rooms (10% chance)

Easy to extend with boss rooms, shops, puzzles, etc.

## Tuning Tips

### More Rooms
```gdscript
# In structure_planner.gd _generate_mine_structure()
var rooms_in_section = rng.randi_range(3, 6)  # Was 2-4
```

### Bigger Rooms
```gdscript
# In structure_planner.gd _generate_room_in_bounds()
var room_width = rng.randi_range(12, 24)  # Was 8-16
var room_height = rng.randi_range(10, 18)  # Was 6-12
```

### Tighter Room Spacing
```gdscript
# In structure_planner.gd _generate_room_in_bounds()
if room_rect.intersects(existing_room.bounds.grow(1)):  # Was 3
```

### More Open Areas
```gdscript
# In mine_rules.json
"weights": {
  "EMPTY": 10,  // Was 5
  "ROCK": 5     // Was 10
}
```

### More Resources
```gdscript
"weights": {
  "ORE": 5,    // Was 2
  "LAVA": 2    // Was 1
}
```

## Disabling Structure Planning

If you want pure WFC without structure:

```gdscript
# In mine_generator.gd
var use_structure_planning: bool = false
```

This reverts to the original "going ham" WFC behavior for comparison.

## Debug Visualization

The F3 debug view shows:
- **Green**: Floors (EMPTY, CORRIDOR, ROOM_FLOOR)
- **Gray**: Walls
- **Orange**: Ore
- **Red**: Lava
- **Yellow**: Doors
- **Gold**: Treasure

Rooms should now appear as organized rectangular green areas connected by corridors!
