extends Control

# References to the image nodes. 
# Change 'TextureRect' to 'Sprite2D' if you are using Sprites instead.
@onready var p1 = $p1
@onready var p2 = $p2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Optional check to ensure nodes are correctly assigned
	if not p1 or not p2:
		print("Error: Make sure nodes named 'p1' and 'p2' exist as children.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# This function is triggered by your Button's signal
func _on_swap_pressed() -> void:
	# Store the first texture in a temporary variable
	var temp_texture = p1.texture
	
	# Swap the textures
	p1.texture = p2.texture
	p2.texture = temp_texture
	
	print("Textures swapped successfully!")
