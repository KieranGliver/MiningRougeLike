extends Control

class_name MineTileMap

# ========== ONREADY VARIABLES ==========

## Reference to the dirt tilemap layer.
@onready var dirt_layer: TileMapLayer = $DirtLayer

## Reference to the treasure layout node.
@onready var treasure_layer: TreasureLayout = $TreasureLayer

## Reference to the bedrock tilemap layer.
@onready var bedrock_layer: TileMapLayer = $BedrockLayer

# ========== EXPORT VARIABLES ==========

## Size of the grid in tiles.
@export var grid_size = Vector2.ZERO

## Whether the mining interaction is disabled.
@export var disabled:bool = false

@export_subgroup("DirtLayerGeneration")
## Noise map size for dirt layer generation.
@export var dirt_noise_size: Vector2 = Vector2(256,256)

## Noise resource used to generate the dirt layer.
@export var dirt_noise: Noise

## Sampling radius for averaging noise values during dirt generation.
@export var dirt_sample_radius = 3

## Current mining tool state, either HAMMER or PICKAXE.
@export_enum("HAMMER", "PICKAXE") var state = "HAMMER":
	set(value):
		state = value
		match(value):
			"HAMMER":
				mine_tool = MineTool.new()
				mine_tool.power = 3
				mine_tool.resistance = 1
				mine_tool.damage = 5
			"PICKAXE":
				mine_tool = MineTool.new()
				mine_tool.power = 4
				mine_tool.resistance = -1
				mine_tool.damage = 3

# ========== INTERNAL VARIABLES ==========

## Random number generator for procedural generation.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## The current mining tool object in use.
var mine_tool: MineTool = MineTool.new()

## Emitted whenever a tile is successfully mined.
signal mined()

# ========== INITIALIZATION ==========

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_minimum_size = grid_size * 16

# ========== LAYER GENERATION ==========

## Generates the mine map using a given seed.
## Initializes dirt, bedrock, and treasure layers.
## @param seed - The random seed used for generation.
func generate(seed: int) -> void:
	state = state  # Reinitialize tool (ensures proper tool setup on generation).
	rng.seed = seed
	generate_dirt_layer(rng.randi())
	generate_bedrock_layer()
	treasure_layer.grid_size = grid_size
	treasure_layer.cell_size = dirt_layer.tile_set.tile_size
	treasure_layer.generate_layout()

## Generates the dirt layer using noise.
## Dirt tiles get different values depending on noise sampling.
## @param seed - Seed for the noise generation.
func generate_dirt_layer(seed: int):
	dirt_noise.seed = seed
	for i in grid_size.x:
		for j in grid_size.y:
			var uv = Vector2(i / float(grid_size.x), j / float(grid_size.y))  ## Normalize coordinates.
			var noise_location = Vector2(dirt_noise_size.x * uv.x, dirt_noise_size.y * uv.y)
			var normalized = (average_noise_value(noise_location, dirt_noise, dirt_sample_radius) + 1) / 2
			var dirt_value = min(int(normalized * 5) + 1, 5)  ## Scale noise to dirt value range [1, 5].
			
			dirt_layer.set_cell(Vector2(i, j), 0, Vector2(dirt_value + 1, 0))

## Generates the bedrock layer as a uniform base layer.
func generate_bedrock_layer():
	for i in grid_size.x:
		for j in grid_size.y:
			bedrock_layer.set_cell(Vector2(i, j), 0, Vector2(0, 0))

## Averages noise values in a square area to smooth out dirt generation.
## @param pos - The position being sampled.
## @param noise - The noise resource.
## @param sample_radius - Radius around pos to sample.
## @return The averaged noise value.
func average_noise_value(pos: Vector2, noise: Noise, sample_radius: int):
	var noise_sum = 0.0
	var sample_count = 0
	for dx in range(-sample_radius, sample_radius + 1):
		for dy in range(-sample_radius, sample_radius + 1):
			var sample_x = pos.x + dx
			var sample_y = pos.y + dy
			var noise_value = noise.get_noise_2d(sample_x, sample_y)
			noise_sum += noise_value
			sample_count += 1
	
	var avg_noise_value = noise_sum / float(sample_count)
	return avg_noise_value

# ========== INPUT ==========

## Handles mouse input for mining.
## Checks if mining is allowed and processes clicks.
## @param event - Input event received from the player.
func _input(event: InputEvent) -> void:
	if not disabled:
		if event is InputEventMouseButton:
			if event.is_pressed():
				var local_position = event.global_position - global_position
				var cell = bedrock_layer.local_to_map(local_position)
				if event.button_index == MOUSE_BUTTON_LEFT and hitcheck_cell(cell) and dirt_layer.get_cell_tile_data(cell).get_custom_data("dirt_value") > 0:
					mine(cell)

# ========== HITCHECK ==========

## Checks if a position in local coordinates is within the grid.
## @param local_position - Position in local space.
## @return True if the position is valid, False otherwise.
func hitcheck_position(local_position: Vector2) -> bool:
	var hit_cell = bedrock_layer.local_to_map(local_position)
	return hitcheck_cell(hit_cell)

## Checks if a cell coordinate is within the grid bounds.
## @param hit_cell - Cell coordinates.
## @return True if the cell is valid, False otherwise.
func hitcheck_cell(hit_cell: Vector2) -> bool:
	return 0 <= hit_cell.x and hit_cell.x < grid_size.x and 0 <= hit_cell.y and hit_cell.y < grid_size.y

# ========== INTERATIONS ==========

## Mines a cell and nearby cells based on the active tool's pattern.
## Reduces dirt values to simulate mining.
## @param cell - The cell being mined.
func mine(cell: Vector2):
	var mine_pattern = mine_tool.get_mine_pattern(cell)
	for i in mine_pattern:
		var pattern_cell = Vector2(i.x, i.y)
		if hitcheck_cell(pattern_cell):
			var atlas_pos = Vector2(max(1, dirt_layer.get_cell_atlas_coords(pattern_cell).x - i.z), 0)
			dirt_layer.set_cell(pattern_cell, 0, atlas_pos)
	emit_signal("mined")

## Calculates the player's score based on treasures they have uncovered.
## Treasures count only if all surrounding dirt has been cleared.
## @return Total score from reachable treasures.
func get_score():
	var reachable_treasures = []
	for treasure in treasure_layer.layout:
		var reachable = true
		treasure = treasure as Treasure
		for x in range(treasure.start_coords.x, treasure.start_coords.x + treasure.shape.get_size().x):
			for y in range(treasure.start_coords.y, treasure.start_coords.y + treasure.shape.get_size().y):
				if treasure.get_bitmap().get_bit(x - treasure.start_coords.x, y - treasure.start_coords.y) and dirt_layer.get_cell_tile_data(Vector2(x, y)).get_custom_data("dirt_value") > 0: 
					reachable = false
		if reachable:
			reachable_treasures.append(treasure)
	
	var score = 0
	for treasure in reachable_treasures:
		treasure = treasure as Treasure
		score += treasure.score 
	
	return score
