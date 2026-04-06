extends Control

@export var main_menu_path: String = "res://Scenes/Menu/main_menu.tscn"
@export var scroll_speed: float = 50.0 # Pixels per second

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var back_button: Button = $BackButton # Make sure the name matches your node tree

var current_scroll: float = 0.0
var finished: bool = false

func _ready() -> void:
	# This line connects the button via code if you haven't done it in the editor
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

func _process(delta: float) -> void:
	if finished:
		return

	# Increment scroll
	current_scroll += scroll_speed * delta
	scroll_container.scroll_vertical = int(current_scroll)
	
	# Check for end of scroll
	var v_bar = scroll_container.get_v_scroll_bar()
	var max_scroll = v_bar.max_value - scroll_container.size.y
	

func _on_back_button_pressed() -> void:
	# Manually return to menu when button is clicked
	get_tree().change_scene_to_file(main_menu_path)
