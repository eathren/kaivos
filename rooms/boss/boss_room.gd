extends Node2D

var TILE_SIZE := GameState.tile_size

var boss_width_tiles: int
var boss_height_tiles: int

func _ready() -> void:
	var view_tiles := _get_view_tiles()
	boss_width_tiles = _round_to_multiple(int(view_tiles.x * 2.5), 8)
	boss_height_tiles = _round_to_multiple(int(view_tiles.y * 1.5), 4)

	print("Boss room size in tiles:", boss_width_tiles, "x", boss_height_tiles)


func _get_view_tiles() -> Vector2i:
	var viewport_size := get_viewport_rect().size
	return Vector2i(
		int(round(viewport_size.x / TILE_SIZE)),
		int(round(viewport_size.y / TILE_SIZE))
	)


func _round_to_multiple(value: int, multiple: int) -> int:
	return int(round(value / float(multiple))) * multiple
