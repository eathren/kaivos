extends CanvasLayer

## Debug overlay showing WFC generation in real-time

@onready var map_display: Control = $MapDisplay
@onready var stats_label: Label = $StatsPanel/StatsLabel

var pixel_size: float = 2.0  # Each tile = 2x2 pixels on minimap
var chunk_size: int = 32
var map_texture: ImageTexture
var map_image: Image

# Color mapping for symbols (matches new tileset)
const SYMBOL_COLORS := {
	"ROCK": Color(0.3, 0.3, 0.3),      # Dark gray (wall center)
	"WALL": Color(0.3, 0.3, 0.3),      # Dark gray
	"EMPTY": Color(0.8, 0.8, 0.7),     # Light tan (floor)
	"CORRIDOR": Color(0.7, 0.7, 0.6),  # Tan (floor variant)
	"ROOM_FLOOR": Color(0.75, 0.75, 0.65), # Tan (floor variant)
	"FLOOR": Color(0.8, 0.8, 0.7),     # Light tan
	"ORE": Color(0.9, 0.7, 0.3),       # Orange/gold (ore)
	"LAVA": Color(1.0, 0.3, 0.0),      # Bright red-orange (lava)
	"DOOR": Color(0.6, 0.4, 0.2),      # Brown (door)
	"TREASURE": Color(1.0, 0.84, 0.0), # Gold (treasure chest)
	"PILLAR": Color(0.5, 0.5, 0.5),    # Gray (pillar)
	"VOID": Color(0.1, 0.0, 0.1),      # Near-black (pit)
	"WATER": Color(0.2, 0.4, 0.8),     # Blue (water/lava)
	"WATER_DEEP": Color(0.1, 0.2, 0.6),# Dark blue
	"GRASS": Color(0.3, 0.6, 0.3),     # Green
	"BARREL": Color(0.5, 0.3, 0.1),    # Dark brown (barrel)
	"CRATE": Color(0.6, 0.5, 0.3),     # Light brown (crate)
	"SHRINE": Color(0.8, 0.6, 1.0),    # Purple (shrine/altar)
	"ALTAR": Color(0.8, 0.6, 1.0),     # Purple
	"WALL_DUNGEON": Color(0.2, 0.2, 0.25), # Dark gray (reinforced)
}

var world_min: Vector2i = Vector2i.ZERO
var world_max: Vector2i = Vector2i.ZERO
var generation_stats := {
	"chunks_generated": 0,
	"total_chunks": 0,
	"cells_generated": 0,
	"symbol_totals": {}
}

func _ready() -> void:
	visible = false
	# Toggle with F3
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		visible = !visible
		if visible:
			update_stats_display()

func initialize_map(min_pos: Vector2i, max_pos: Vector2i) -> void:
	"""Initialize the minimap image with world bounds"""
	world_min = min_pos
	world_max = max_pos
	
	var width := int((max_pos.x - min_pos.x + 1) * pixel_size)
	var height := int((max_pos.y - min_pos.y + 1) * pixel_size)
	
	print("[Debug] Initializing minimap: %dx%d pixels for world %s to %s" % [width, height, min_pos, max_pos])
	
	map_image = Image.create(width, height, false, Image.FORMAT_RGB8)
	map_image.fill(Color.BLACK)  # Start with black (ungenerated)
	
	map_texture = ImageTexture.create_from_image(map_image)
	
	# Create TextureRect if it doesn't exist
	if not map_display.has_node("MapTexture"):
		var texture_rect := TextureRect.new()
		texture_rect.name = "MapTexture"
		texture_rect.texture = map_texture
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		map_display.add_child(texture_rect)
	else:
		map_display.get_node("MapTexture").texture = map_texture

func paint_chunk(chunk_pos: Vector2i, symbol_grid: Array) -> void:
	"""Paint a chunk's symbols onto the minimap"""
	if map_image == null:
		return
	
	var chunk_world_origin := chunk_pos * chunk_size
	
	for y in range(symbol_grid.size()):
		for x in range(symbol_grid[0].size()):
			var world_pos := Vector2i(chunk_world_origin.x + x, chunk_world_origin.y + y)
			var symbol: String = symbol_grid[y][x]
			
			# Convert world position to image pixel
			var img_x := int((world_pos.x - world_min.x) * pixel_size)
			var img_y := int((world_pos.y - world_min.y) * pixel_size)
			
			# Get color for symbol
			var color = SYMBOL_COLORS.get(symbol, Color.MAGENTA)  # Magenta for unknown
			
			# Paint pixel (and neighbors if pixel_size > 1)
			for py in range(int(pixel_size)):
				for px in range(int(pixel_size)):
					var final_x := img_x + px
					var final_y := img_y + py
					if final_x >= 0 and final_x < map_image.get_width() and \
					   final_y >= 0 and final_y < map_image.get_height():
						map_image.set_pixel(final_x, final_y, color)
			
			# Track symbol stats
			if symbol not in generation_stats.symbol_totals:
				generation_stats.symbol_totals[symbol] = 0
			generation_stats.symbol_totals[symbol] += 1
	
	# Update texture
	map_texture.update(map_image)
	generation_stats.cells_generated += symbol_grid.size() * symbol_grid[0].size()

func update_chunk_progress(generated: int, total: int) -> void:
	"""Update progress stats"""
	generation_stats.chunks_generated = generated
	generation_stats.total_chunks = total
	update_stats_display()

func update_stats_display() -> void:
	"""Update the stats label"""
	if not stats_label:
		return
	
	var text := "[WFC Generation Debug]\n\n"
	text += "Chunks: %d/%d (%.1f%%)\n" % [
		generation_stats.chunks_generated,
		generation_stats.total_chunks,
		(float(generation_stats.chunks_generated) / max(1, generation_stats.total_chunks)) * 100.0
	]
	text += "Cells: %d\n\n" % generation_stats.cells_generated
	
	text += "Symbol Distribution:\n"
	for symbol in generation_stats.symbol_totals:
		var count: int = generation_stats.symbol_totals[symbol]
		var percent = (float(count) / max(1, generation_stats.cells_generated)) * 100.0
		text += "  %s: %d (%.1f%%)\n" % [symbol, count, percent]
	
	text += "\nPress F3 to toggle"
	
	stats_label.text = text

func highlight_clearing(clearing_bounds: Dictionary) -> void:
	"""Draw a rectangle showing the clearing area"""
	if map_image == null:
		return
	
	var left: int = clearing_bounds.left
	var right: int = clearing_bounds.right
	var top: int = clearing_bounds.top
	var bottom: int = clearing_bounds.bottom
	
	# Draw red rectangle outline
	var highlight_color := Color.RED
	
	for x in range(left, right + 1):
		for offset in range(int(pixel_size)):
			# Top and bottom edges
			var top_img := Vector2i(int((x - world_min.x) * pixel_size) + offset, int((top - world_min.y) * pixel_size))
			var bottom_img := Vector2i(int((x - world_min.x) * pixel_size) + offset, int((bottom - world_min.y) * pixel_size))
			
			if top_img.x >= 0 and top_img.x < map_image.get_width() and top_img.y >= 0 and top_img.y < map_image.get_height():
				map_image.set_pixel(top_img.x, top_img.y, highlight_color)
			if bottom_img.x >= 0 and bottom_img.x < map_image.get_width() and bottom_img.y >= 0 and bottom_img.y < map_image.get_height():
				map_image.set_pixel(bottom_img.x, bottom_img.y, highlight_color)
	
	for y in range(top, bottom + 1):
		for offset in range(int(pixel_size)):
			# Left and right edges
			var left_img := Vector2i(int((left - world_min.x) * pixel_size), int((y - world_min.y) * pixel_size) + offset)
			var right_img := Vector2i(int((right - world_min.x) * pixel_size), int((y - world_min.y) * pixel_size) + offset)
			
			if left_img.x >= 0 and left_img.x < map_image.get_width() and left_img.y >= 0 and left_img.y < map_image.get_height():
				map_image.set_pixel(left_img.x, left_img.y, highlight_color)
			if right_img.x >= 0 and right_img.x < map_image.get_width() and right_img.y >= 0 and right_img.y < map_image.get_height():
				map_image.set_pixel(right_img.x, right_img.y, highlight_color)
	
	map_texture.update(map_image)
