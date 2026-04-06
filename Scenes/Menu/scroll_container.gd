extends ScrollContainer

@export var scroll_speed: float = 30.0  # Lower = slower (Minecraft is ~20-30)

func _ready():
	# Disable the scrollbar visually
	get_v_scroll_bar().modulate = Color(0, 0, 0, 0)

func _process(delta):
	scroll_vertical += int(scroll_speed * delta)
	
	# Optional: go back to menu when done
	if scroll_vertical >= get_v_scroll_bar().max_value:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
