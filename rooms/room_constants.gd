extends Node

## Room generation constants
## Lock these values for your entire dungeon system

const ROOM_TILES := Vector2i(16, 12)  # Room size in tiles
const TILE_SIZE := 16  # Pixels per tile
const ROOM_SIZE_PX := ROOM_TILES * TILE_SIZE  # 256x192 pixels per room

## Door bit flags
enum DoorFlags {
	UP = 1,      # 0001
	RIGHT = 2,   # 0010
	DOWN = 4,    # 0100
	LEFT = 8     # 1000
}

## Convert direction vector to door bit
static func dir_to_bit(dir: Vector2i) -> int:
	if dir == Vector2i.UP:
		return DoorFlags.UP
	if dir == Vector2i.RIGHT:
		return DoorFlags.RIGHT
	if dir == Vector2i.DOWN:
		return DoorFlags.DOWN
	if dir == Vector2i.LEFT:
		return DoorFlags.LEFT
	return 0

## Convert door bit to direction vector
static func bit_to_dir(bit: int) -> Vector2i:
	match bit:
		DoorFlags.UP:
			return Vector2i.UP
		DoorFlags.RIGHT:
			return Vector2i.RIGHT
		DoorFlags.DOWN:
			return Vector2i.DOWN
		DoorFlags.LEFT:
			return Vector2i.LEFT
	return Vector2i.ZERO
