extends Control

@onready var woody_rect = $VBoxContainer/PlayerSelection/Woody
@onready var buzz_rect = $VBoxContainer/PlayerSelection/Buzz

var Menu_scene_path = "res://Scenes/Menu/Main_Menu.tscn"

func _ready() -> void:
	if Global.players_swapped:
		_apply_visual_swap()

func _on_swap_pressed() -> void:
	Global.players_swapped = !Global.players_swapped
	_apply_visual_swap()
	
	print("Players swapped: ", Global.players_swapped)

func _apply_visual_swap() -> void:
	var temp_texture = woody_rect.texture
	woody_rect.texture = buzz_rect.texture
	buzz_rect.texture = temp_texture


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Menu_scene_path)
