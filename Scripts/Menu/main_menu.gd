extends Control

var game_scene_path = "res://Scenes/Main.tscn"
var settings_scene_path = "res://Scenes/Menu/settings.tscn"
var credits_scene_path = "res://Scenes/Credits.tscn"


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(settings_scene_path)

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(credits_scene_path)

func _on_exit_pressed() -> void:
	get_tree().quit()
