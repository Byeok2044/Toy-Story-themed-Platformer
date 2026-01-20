extends Control

# References to the actual node names in your Settings.tscn
@onready var woody_rect = $VBoxContainer/PlayerSelection/Woody
@onready var buzz_rect = $VBoxContainer/PlayerSelection/Buzz

var Menu_scene_path = "res://Scenes/Menu/Main_Menu.tscn"

func _ready() -> void:
	# Ensure the UI matches the current global state when the menu opens
	if Global.players_swapped:
		_apply_visual_swap()

func _on_swap_pressed() -> void:
	# 1. Toggle the global swap state
	Global.players_swapped = !Global.players_swapped
	
	# 2. Update the visual textures in the menu
	_apply_visual_swap()
	
	print("Players swapped: ", Global.players_swapped)

func _apply_visual_swap() -> void:
	# Swaps the textures of the Woody and Buzz nodes
	var temp_texture = woody_rect.texture
	woody_rect.texture = buzz_rect.texture
	buzz_rect.texture = temp_texture


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Menu_scene_path)
