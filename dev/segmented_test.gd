extends Node2D

## Test scene for segmented mine generation

@onready var target_map: TileMapLayer = $TargetMap
@onready var camera: Camera2D = $Camera2D


const SegmentedMineGenerator = preload("res://systems/generation/segmented_mine_generator.gd")

func _ready() -> void:
	print("=== Segmented Mine Generator Test ===")
	print("Generating...")
	
	var gen = SegmentedMineGenerator.new()
	var result = gen.generate(12345)
	
	# Apply to tilemap
	_apply_layout(result)
	
	# Center camera
	var bounds = result["bounds"]
	camera.position = Vector2(bounds.x * 8, bounds.y * 8)
	
	print("Generation complete! Press ESC to quit")

func _apply_layout(result: Dictionary) -> void:
	target_map.clear()
	
	var layout = result["layout_map"]
	var source_id = 6
	
	# Tile coordinates
	var tiles = {
		SegmentedMineGenerator.TileType.FLOOR: Vector2i(1, 5),
		SegmentedMineGenerator.TileType.WALL: Vector2i(1, 1),
		SegmentedMineGenerator.TileType.ORE: Vector2i(0, 6),
		SegmentedMineGenerator.TileType.LAVA: Vector2i(3, 6),
		SegmentedMineGenerator.TileType.SHRINE: Vector2i(4, 7)
	}
	
	for pos in layout:
		var tile_type = layout[pos]
		var tile_coord = tiles.get(tile_type, Vector2i(1, 1))
		target_map.set_cell(pos, source_id, tile_coord)
	
	print("[Test] Applied %d tiles" % layout.size())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
