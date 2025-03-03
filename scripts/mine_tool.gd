extends Resource

class_name MineTool

## The power of the mining tool, which affects how far it can mine.
@export var power: int = 1

## The resistance of the mining tool, which impacts how much damage it takes before breaking.
@export var resistance: int = 1

## The damage the tool does when mining.
@export var damage: int = 1

## Returns the neighboring cells of a given cell.
## This is used to determine which surrounding tiles can be mined.
## @param cell - The cell for which to find neighbors.
## @return An array of Vector2 coordinates representing neighboring cells.
func get_neighbours(cell: Vector2) -> Array[Vector2]:
	return [Vector2(cell.x - 1, cell.y), Vector2(cell.x + 1, cell.y), Vector2(cell.x, cell.y - 1), Vector2(cell.x, cell.y + 1)]

## Generates a mining pattern based on the tool's power and resistance.
## This pattern is used to determine the cells affected by mining.
## @param cell - The starting cell where mining begins.
## @return An array of Vector3 coordinates representing the cells to mine. Each Vector3 holds the x, y coordinates and the power of the tool at that cell.
func get_mine_pattern(cell: Vector2) -> Array[Vector3]:
	var mine_pattern: Array[Vector3] = []  # Array to hold the mine pattern.
	var visited: Dictionary = {}  # Dictionary to track visited cells and their power.
	var queue: Array = [{"cell": cell, "power": power, "resistance": resistance}]  ## Queue to process cells for mining.

	# While there are cells to process in the queue.
	while queue.size() > 0:
		var current = queue.pop_front()  # Pop the first element from the queue.
		var current_cell = current["cell"]  # The current cell being processed.
		var current_power = current["power"]  # The remaining power for the current cell.
		var current_resistance = current["resistance"]  # The remaining resistance for the current cell.
		
		# If power is 0, stop processing for this cell.
		if current_power == 0:
			continue
		
		# Create a unique key for the current cell to track visits.
		var key = str(current_cell.x) + "," + str(current_cell.y)
		if key in visited:
			var prev_power = visited[key][0]  # Get the previous power for the cell.
			if prev_power >= current_power:
				continue  # Skip if the current power is less than or equal to the previous one.
		
		# Mark the current cell as visited with its power and resistance.
		visited[key] = [current_power, current_resistance]
		mine_pattern.append(Vector3(current_cell.x, current_cell.y, current_power))  ## Add the current cell to the mine pattern.
		
		# Process the neighboring cells.
		for n in get_neighbours(current_cell):
			var next_power = current_power  # Start with the current power for the neighbor.
			if current_resistance <= 0:
				next_power = max(next_power + current_resistance - 1, 0)  # Reduce power based on resistance.

			# Adjust the next resistance based on the current resistance.
			var next_resistance = min(max(0, current_resistance - 1), current_resistance + 1)
			queue.append({"cell": n, "power": next_power, "resistance": next_resistance})  # Add the neighbor to the queue for processing.
	
	return mine_pattern  # Return the generated mine pattern.
