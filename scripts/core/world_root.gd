extends Node2D

@export var base_scroll_speed: float = GameState.get_trawler_speed()

var depth: float = 0.0
var dig_multiplier: float = 1.0

# WorldRoot is now just a container for the Wall TileMapLayer
# Level generation is handled by Level_Mine.gd using MineGenerator
