extends RefCounted
class_name Wfc

## Wave Function Collapse algorithm implementation
## Generates grids of symbols based on adjacency rules

var symbols: PackedStringArray
var weights: Dictionary  # symbol -> float
var neighbors: Dictionary  # symbol -> { "N": [...], "E": [...], "S": [...], "W": [...] }
var rng: RandomNumberGenerator

var width: int
var height: int
var grid: Array  # Array[Cell]

# Direction vectors
const DIRS := {
	"N": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"S": Vector2i(0, 1),
	"W": Vector2i(-1, 0)
}

const OPPOSITE := {
	"N": "S",
	"E": "W",
	"S": "N",
	"W": "E"
}

class Cell:
	var possible: PackedInt32Array  # Indices of possible symbols
	var collapsed: bool = false
	var symbol_index: int = -1  # Index into symbols array when collapsed

func _init():
	rng = RandomNumberGenerator.new()

func load_rules(json_path: String) -> bool:
	"""Load WFC rules from JSON file"""
	if not FileAccess.file_exists(json_path):
		push_error("WFC rules file not found: " + json_path)
		return false
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Failed to open WFC rules: " + json_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse WFC rules JSON: " + json.get_error_message())
		return false
	
	var data = json.data
	
	# Load symbols
	symbols = PackedStringArray(data["symbols"])
	
	# Load weights
	weights = data["weights"]
	
	# Load neighbor rules
	neighbors = data["neighbors"]
	
	return true

func init_grid(w: int, h: int, seed_value: int = -1) -> void:
	"""Initialize the grid with all possibilities"""
	width = w
	height = h
	
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	
	# Create grid
	grid = []
	for y in range(height):
		var row := []
		for x in range(width):
			var cell := Cell.new()
			# All symbols are possible initially
			cell.possible = PackedInt32Array()
			for i in range(symbols.size()):
				cell.possible.append(i)
			row.append(cell)
		grid.append(row)

func get_cell(x: int, y: int) -> Cell:
	"""Get cell at position, null if out of bounds"""
	if x < 0 or x >= width or y < 0 or y >= height:
		return null
	return grid[y][x]

func find_lowest_entropy_cell() -> Vector2i:
	"""Find uncollapsed cell with fewest possibilities"""
	var min_entropy := 999999
	var candidates: Array[Vector2i] = []
	
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if cell.collapsed:
				continue
			
			var entropy := cell.possible.size()
			if entropy == 0:
				# Contradiction - this should not happen if rules are valid
				return Vector2i(-1, -1)
			
			if entropy < min_entropy:
				min_entropy = entropy
				candidates.clear()
				candidates.append(Vector2i(x, y))
			elif entropy == min_entropy:
				candidates.append(Vector2i(x, y))
	
	if candidates.is_empty():
		return Vector2i(-1, -1)  # All collapsed
	
	# Pick random cell from candidates with same entropy
	return candidates[rng.randi() % candidates.size()]

func collapse_cell(x: int, y: int) -> bool:
	"""Collapse a cell to a single symbol based on weights"""
	var cell := get_cell(x, y)
	if not cell or cell.collapsed:
		return false
	
	# Calculate weighted random selection
	var total_weight := 0.0
	for idx in cell.possible:
		var sym := symbols[idx]
		total_weight += weights.get(sym, 1.0)
	
	var rand_val := rng.randf() * total_weight
	var accumulated := 0.0
	
	for idx in cell.possible:
		var sym := symbols[idx]
		accumulated += weights.get(sym, 1.0)
		if rand_val <= accumulated:
			cell.symbol_index = idx
			cell.collapsed = true
			return true
	
	# Fallback - shouldn't happen but pick first
	cell.symbol_index = cell.possible[0]
	cell.collapsed = true
	return true

func propagate_constraints(x: int, y: int) -> bool:
	"""Propagate constraints from collapsed cell to neighbors"""
	var stack: Array[Vector2i] = [Vector2i(x, y)]
	var visited := {}
	
	while not stack.is_empty():
		var pos = stack.pop_back()
		var key := "%d,%d" % [pos.x, pos.y]
		
		if key in visited:
			continue
		visited[key] = true
		
		var cell := get_cell(pos.x, pos.y)
		if not cell:
			continue
		
		# Check all four directions
		for dir_name in DIRS:
			var dir_vec = DIRS[dir_name]
			var nx = pos.x + dir_vec.x
			var ny = pos.y + dir_vec.y
			var neighbor := get_cell(nx, ny)
			
			if not neighbor or neighbor.collapsed:
				continue
			
			# Constrain neighbor based on current cell's possibilities
			var old_count := neighbor.possible.size()
			var valid_symbols := {}
			
			# For each possible symbol in current cell
			for idx in cell.possible:
				var sym := symbols[idx]
				if sym not in neighbors:
					continue
				
				var allowed = neighbors[sym].get(dir_name, [])
				for allowed_sym in allowed:
					valid_symbols[allowed_sym] = true
			
			# Filter neighbor possibilities
			var new_possible := PackedInt32Array()
			for idx in neighbor.possible:
				var sym := symbols[idx]
				if sym in valid_symbols:
					new_possible.append(idx)
			
			neighbor.possible = new_possible
			
			# If we reduced possibilities, add to stack
			if neighbor.possible.size() < old_count:
				if neighbor.possible.size() == 0:
					# Contradiction
					return false
				stack.append(Vector2i(nx, ny))
	
	return true

func step() -> bool:
	"""Perform one WFC step. Returns false if contradiction or complete"""
	var pos := find_lowest_entropy_cell()
	
	if pos.x < 0:
		# Either complete or contradiction
		return false
	
	if not collapse_cell(pos.x, pos.y):
		return false
	
	if not propagate_constraints(pos.x, pos.y):
		# Contradiction - would need to backtrack or restart
		return false
	
	return true

func run_to_completion(max_iterations: int = 10000) -> bool:
	"""Run WFC until complete or contradiction. Returns true if successful"""
	var iterations := 0
	
	while iterations < max_iterations:
		if not step():
			# Check if actually complete
			return is_complete()
		iterations += 1
	
	push_error("WFC exceeded max iterations (%d)" % max_iterations)
	return false

func is_complete() -> bool:
	"""Check if all cells are collapsed"""
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if not cell.collapsed:
				return false
	return true

func get_symbol_grid() -> Array:
	"""Return 2D array of symbol strings"""
	var result := []
	for y in range(height):
		var row := []
		for x in range(width):
			var cell := get_cell(x, y)
			if cell.collapsed and cell.symbol_index >= 0:
				row.append(symbols[cell.symbol_index])
			else:
				row.append("UNKNOWN")
		result.append(row)
	return result

func get_symbol_at(x: int, y: int) -> String:
	"""Get symbol at position"""
	var cell := get_cell(x, y)
	if not cell or not cell.collapsed or cell.symbol_index < 0:
		return "UNKNOWN"
	return symbols[cell.symbol_index]
