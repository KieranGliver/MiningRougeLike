extends Resource

class_name Treasure

# Basic properties of the Treasure
@export var name: String = ""
@export var shape: Texture2D # Bitmap of used for collision and placement
@export var sprite: Texture2D # Sprite used for visual display
@export var score: int = 1 # Score awarded when this treasure is mined

# coordinates of placement in the mine grid
var coords: Vector2 = Vector2.ZERO

func get_bitmap():
	if shape == null:
		return null
	
	# Extract image data from the shape texture
	var image = shape.get_image()
	
	# Create a new BitMap to represent the treasure's shape mask
	var bitmap = BitMap.new()
	
	# Fill the BitMap based on the shape's alpha channel (transparent areas are excluded)
	bitmap.create_from_image_alpha(image)
	
	# Assign it to the mask
	return bitmap
