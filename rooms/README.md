# Room Template System - Usage Guide

## Quick Start

### 1. Room Grid Setup
- **Room Size**: 16x12 tiles (256x192 pixels)
- **Tile Size**: 16 pixels
- Constants defined in `rooms/room_constants.gd`

### 2. Door Masks
Doors use bit flags:
- **Up**: 1 (0001)
- **Right**: 2 (0010)
- **Down**: 4 (0100)
- **Left**: 8 (1000)

Example: A room with doors on Up and Right = 1 | 2 = 3

### 3. File Structure
```
rooms/
├── room_constants.gd          # Room size constants and helpers
├── room_template.gd            # Base RoomTemplate class
├── room_template.tscn          # Base template scene (don't use directly)
├── dungeon_layout.gd           # Layout generator (drunk walk algorithm)
├── dungeon_builder.gd          # Example builder script
└── templates/                  # Your room variants
    ├── room_start_a.tscn
    ├── room_combat_a.tscn
    └── room_combat_b.tscn
```

### 4. Creating New Room Templates

1. **Duplicate** an existing template in `rooms/templates/`
2. **Set Properties** in the Inspector:
   - `room_type`: "start", "combat", "shop", "boss", etc.
   - `door_mask`: Which sides have doors (use flags above)
3. **Add Markers** as children of the appropriate marker nodes:
   - Add `Marker2D` nodes to `Markers/DoorMarkers/` and add to group `room_door`
   - Add `Marker2D` nodes to `Markers/LootMarkers/` and add to group `room_loot`
   - Add `Marker2D` nodes to `Markers/EnemyMarkers/` and add to group `room_enemy`
4. **Design Layout**:
   - Paint tiles in `FloorLayer` and `WallLayer`
   - Leave openings in walls where doors are

### 5. Register New Templates

Edit `autoloads/room_library.gd` in the `_register_rooms()` function:

```gdscript
func _register_rooms() -> void:
    _register("res://rooms/templates/room_start_a.tscn")
    _register("res://rooms/templates/room_combat_a.tscn")
    _register("res://rooms/templates/room_combat_b.tscn")
    _register("res://rooms/templates/room_shop_a.tscn")  # Add your new room
```

### 6. Using the System

In your level/dungeon scene:

```gdscript
extends Node2D

const RoomConstants = preload("res://rooms/room_constants.gd")

func build_dungeon():
    # Generate layout
    var layout = DungeonLayout.generate_layout(10)
    
    # Create rooms
    for room_node in layout:
        var scene = RoomLibrary.get_random(room_node.mask, room_node.room_type)
        var room = scene.instantiate()
        add_child(room)
        room.position = Vector2(room_node.grid_pos) * RoomConstants.ROOM_SIZE_PX
        
        # Populate with enemies/loot
        for marker in room.get_enemy_markers():
            spawn_enemy(marker.global_position)
```

### 7. Testing

Start simple:
1. Use `DungeonLayout.generate_linear_layout(5)` for a straight line of rooms
2. Set `use_linear_layout = true` in `dungeon_builder.gd`
3. Test enemy and loot spawning
4. Switch to `generate_layout()` for proper procedural generation

### 8. Autoloads

The system uses one autoload:
- **RoomLibrary**: `autoloads/room_library.gd` (already added to project.godot)

## API Reference

### RoomTemplate
- `get_door_markers() -> Array[Node2D]`
- `get_loot_markers() -> Array[Node2D]`
- `get_enemy_markers() -> Array[Node2D]`
- `has_door(direction_bit: int) -> bool`

### RoomLibrary
- `get_random_by_mask(mask: int) -> PackedScene`
- `get_random_by_type(type: String) -> PackedScene`
- `get_random(mask: int, type: String = "") -> PackedScene`

### DungeonLayout
- `generate_layout(max_rooms: int = 10, seed_value: int = -1) -> Array[RoomNode]`
- `generate_linear_layout(room_count: int = 5) -> Array[RoomNode]`

### RoomConstants
- `ROOM_TILES: Vector2i(16, 12)`
- `TILE_SIZE: int = 16`
- `ROOM_SIZE_PX: Vector2i(256, 192)`
- `dir_to_bit(dir: Vector2i) -> int`
- `bit_to_dir(bit: int) -> Vector2i`
