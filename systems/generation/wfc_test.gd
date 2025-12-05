extends Node2D

## Test scene for WFC generation
## Run this scene to see WFC in action

@onready var tilemap: TileMap = $TileMap

func _ready() -> void:
	generate_test_world()

func generate_test_world() -> void:
	var world_seed := "kaivos-test-world-1"
	var seed_value := WfcHelper.seed_from_string(world_seed)
	
	print("Generating WFC world with seed: ", world_seed, " (", seed_value, ")")
	
	var symbol_grid := WfcHelper.generate_chunk(
		"res://data/wfc/mine_rules.json",
		32,  # 32x32 chunk
		seed_value
	)
	
	if symbol_grid.is_empty():
		print("Generation failed!")
		return
	
	print("Generation complete! Painting to tilemap...")
	WfcHelper.paint_to_tilemap(tilemap, symbol_grid, 0)
	print("Done!")

func _input(event: InputEvent) -> void:
	# Press R to regenerate
	if event.is_action_pressed("ui_accept"):
		generate_test_world()
