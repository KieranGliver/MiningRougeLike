extends Node2D

class_name TreasureLayout

# ========== EXPORT VARIABLES ==========

## List of possible treasures to place
@export var data: Array[Treasure] = []
## List of treasures successfully placed during generation.
@export var layout: Array[Treasure] = []
## Path to treasure resource folder
@export var treasure_path: String = "res://resources/treasure/"

# ========== INTERNAL VARIABLES ==========

# Grid properties
## Grid size in cells.
var grid_size: Vector2 = Vector2.ZERO
## Size of each grid cell in pixels.
var cell_size: Vector2 = Vector2.ZERO

## Tracks occupied cells to avoid overlap (keys = Vector2i positions).
var occupied_cells: Dictionary = {} # Tracks occupied grid cells to prevent overlapping

## Maximum number of attempts to place a treasure before giving up.
const MAX_ATTEMPTS := 30  # Maximum attempts to place treasure

## List of all possible treasure resources
var treasure_resources: Array = []

# ========== INITIALIZATION ==========

## Initializes the grid and cell size for the layout.
## @param new_grid_size - The dimensions of the grid (columns, rows).
## @param new_cell_size - The size of each individual grid cell in pixels.
func _init(new_grid_size: Vector2 = Vector2.ZERO, new_cell_size: Vector2 = Vector2.ZERO) -> void:
	grid_size = new_grid_size
	cell_size = new_cell_size

## Loads treasures resources from treasure path to array.
func grab_treasures():
	var treasure_files = DirAccess.open(treasure_path)
	
	if treasure_files:
		treasure_files.list_dir_begin()
		while true:
			var file = treasure_files.get_next()
			if file == "":
				break
			if file.ends_with(".tres"): # Ensure it's a .tres file (Treasure resource)
				var treasure = load(treasure_path + file) as Treasure
				if treasure:
					treasure_resources.append(treasure)
		treasure_files.list_dir_end()

func _ready():
	grab_treasures()

# ========== MAIN LAYOUT GENERATION ==========

## Generates a new randomized layout of treasures within the grid.
## Places treasures while ensuring they don't overlap.
func generate_layout() -> void:
	layout.clear()
	occupied_cells.clear()
	
	generate_mine_data(5)
	
	# Sort treasures by area (largest first for better fit)
	data.sort_custom(func(a,b): 
		return a.shape.get_size().length_squared() > b.shape.get_size().length_squared()
	)
	
	var placed_treasures: Array[Treasure] = []
	var unplaced_treasures: Array[Treasure] = []
	
	# Try placing each treasure within MAX_ATTEMPTS
	for treasure in data:
		var placed = false
		
		for _i in range(MAX_ATTEMPTS):
			var new_pos = get_random_position(treasure.shape.get_size())
			var treasure_bitmap = treasure.get_bitmap()
			
			if can_place_treasure(new_pos, treasure_bitmap):
				var new_treasure = treasure.duplicate()
				new_treasure.coords = new_pos
				
				mark_occupied(new_pos, treasure_bitmap)
				layout.append(new_treasure)
				placed_treasures.append(new_treasure)
				placed = true
				break
		
		if not placed:
			unplaced_treasures.append(treasure)
	
	# If treasures couldn't be placed, attempt backtracking placement
	if not unplaced_treasures.is_empty():
		backtrack_placement(unplaced_treasures)
	
	spawn_layout()

## Picks random treasures from resources with sum of scores under total score
## @param total_score - Total score that treasures contain.
func generate_mine_data(total_score: int):
	var current_score = 0
	var selected_treasures: Array[Treasure] = []
	
	while current_score < total_score:
		var treasure = treasure_resources[randi() % treasure_resources.size()]
		if current_score + treasure.score <= total_score:
			selected_treasures.append(treasure)
			current_score += treasure.score
	
	data = selected_treasures

# ========== VISUALIZATION ==========

## Spawns the placed treasures as Sprite2D nodes for visualization.
## Any existing treasure sprites are freed before spawning new ones.
func spawn_layout():
	# Clean up any existing sprites
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	
	# Add new treasure sprites
	for treasure in layout:
		var sprite = Sprite2D.new()
		var offset = cell_size*treasure.shape.get_size()/2
		sprite.texture = treasure.sprite
		sprite.position = treasure.coords * cell_size + offset
		add_child(sprite)

# ========== TREASURE PLACEMENT LOGIC ==========

## Returns a random position within the grid where the treasure can fit.
## @param size - Size of the treasure in grid cells.
## @return Random Vector2i position within the grid.
func get_random_position(size: Vector2i) -> Vector2i:
	return Vector2i(
		randi_range(0, grid_size.x - size.x),
		randi_range(0, grid_size.y - size.y)
	)

## Checks if a treasure can be placed at a given position without overlapping existing treasures.
## @param pos - Top-left position to check.
## @param shape - The treasure's shape bitmap.
## @return True if the treasure can be placed, False if it overlaps.
func can_place_treasure(pos: Vector2i, shape: BitMap) -> bool:
	for x in range(pos.x, pos.x + shape.get_size().x):
		for y in range(pos.y, pos.y + shape.get_size().y):
			if shape.get_bit(x - pos.x, y - pos.y):  
				if occupied_cells.has(Vector2i(x, y)):
					return false
	return true

## Marks grid cells as occupied based on the treasure's shape.
## @param pos - Top-left position where the treasure is placed.
## @param shape - The treasure's shape bitmap.
func mark_occupied(pos: Vector2i, shape: BitMap) -> void:
	for x in range(pos.x, pos.x + shape.get_size().x):
		for y in range(pos.y, pos.y + shape.get_size().y):
			if shape.get_bit(x - pos.x, y - pos.y):  
				occupied_cells[Vector2i(x, y)] = true

# ========== BACKTRACKING LOGIC ==========

## Attempts to place treasures that couldn't be placed initially using a brute force approach.
## This iterates over all valid positions to find space for unplaced treasures.
## @param unplaced_treasures - List of treasures that failed to place initially.acking
func backtrack_placement(unplaced_treasures: Array[Treasure]):
	for treasure in unplaced_treasures:
		for x in range(grid_size.x - treasure.shape.get_size().x + 1):
			for y in range(grid_size.y - treasure.shape.get_size().y + 1):
				var pos = Vector2i(x, y)
				
				if can_place_treasure(pos, treasure.get_bitmap()):
					var new_treasure = treasure.duplicate()
					new_treasure.coords = pos

					mark_occupied(pos, new_treasure.get_bitmap())
					layout.append(new_treasure)
					break  # Move to next unplaced treasure after successful placement
