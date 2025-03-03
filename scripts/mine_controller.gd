extends Control

class_name GameController

# ========== ONREADY VARIABLES ==========

## The VBoxContainer that holds the main game interface.
@onready var main: VBoxContainer = $GameVBox/GameMargin/GameMain

## The ProgressBar used to show the integrity of the mine.
@onready var mine_integrity_bar: ProgressBar = $GameVBox/GameMargin/GameMain/ProgressBar

# ========== EXPORT VARIABLES ==========

## The maximum health of the mine, which represents how much damage the mine can take before breaking.
@export var max_health = 50

## The scene for the mine tile map, preloaded for use during the game.
@export var game = preload("res://scenes/mine_tile_map.tscn")

# ========== INTERNAL VARIABLES ==========

## The MineTileMap instance that handles the mining logic and tile updates.
var tilemap: MineTileMap = null

## The current health of the mine, starts at max_health and decreases as the mine is damaged.
var current_health = 0

## The RandomNumberGenerator used for generating random seeds for the tile map.
var rng = RandomNumberGenerator.new()

# ========== INTIALIZATION ==========

## Called when the node enters the scene tree for the first time.
## Starts the game by initializing the mine and setting health to max.
func _ready() -> void:
	start()

## Starts or restarts the game by resetting the mine health and generating a new tile map.
func start():
	# If a tilemap already exists, remove it from the scene.
	if tilemap:
		tilemap.queue_free()
	
	# Reset the current health to the maximum health.
	current_health = max_health
	
	# Instantiate a new mine tile map scene and connect its "mined" signal to handle damage.
	tilemap = game.instantiate()
	tilemap.connect("mined", _on_tile_maps_mined)
	main.add_child(tilemap)  ## Add the new tilemap to the main UI.
	
	# Generate the tile map with a random seed.
	tilemap.generate(rng.randi())
	
	# Update the mine integrity bar to reflect the current health.
	update_mine_integrity()

# ========== BUTTON FUNCTIONS ==========
## Changes the mining tool to "HAMMER" when the hammer button is pressed.
func _on_hammer_button_pressed() -> void:
	tilemap.state = "HAMMER"

## Changes the mining tool to "PICKAXE" when the pickaxe button is pressed.
func _on_pickaxe_button_pressed() -> void:
	tilemap.state = "PICKAXE"

## Starts a new game when the "start" button is pressed by resetting the game.
func _on_start_button_pressed() -> void:
	start()

# ========== INTEGRITY ==========

## This function is called when the "mined" signal is emitted from the tilemap.
## It decreases the current health based on the damage caused by the mining tool.
func _on_tile_maps_mined() -> void:
	current_health -= tilemap.mine_tool.damage
	
	# If the mine's health reaches 0 or below, disable further mining.
	if current_health <= 0:
		tilemap.disabled = true
	
	# Update the mine integrity bar to reflect the current health.
	update_mine_integrity()

## Updates the mine integrity bar to show the current health.
## Sets the maximum value to the max health and the current value to the current health.
func update_mine_integrity():
	mine_integrity_bar.max_value = max_health
	mine_integrity_bar.value = current_health
