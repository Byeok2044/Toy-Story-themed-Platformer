extends Control

var game_scene_path = "res://Scenes/Main.tscn"
var controls_scene_path = "res://Scenes/Menu/Controls.tscn"
var settings_scene_path = "res://Scenes/Menu/settings.tscn"
var credits_scene_path = "res://Scenes/Menu/Credits.tscn"

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var settings: Panel = $Settings
@onready var title: Label = $Title

func _ready():
	title.visible = true
	main_buttons.visible = true
	settings.visible = false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file(controls_scene_path)

func _on_settings_pressed() -> void:
	title.visible = false
	main_buttons.visible = false
	settings.visible = true


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(credits_scene_path)

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	_ready()
