extends CheckButton

func _on_toggled(toggled_on: bool) -> void:
	if Engine.is_embedded_in_editor():
		print("Fullscreen not supported in embedded view.")
		return

	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
