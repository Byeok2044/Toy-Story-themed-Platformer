extends Node2D

# Global variables and state tracking
var playerBody: CharacterBody2D
var respawn_point = null
var players_swapped: bool = false
var dead_enemies: Array = []

@onready var pause_menu: Control = $HUD/PauseMenu # Replace with your actual menu container name
@onready var pause_button: Button = $HUD/Pause

func _ready() -> void:
	# Ensure this node can process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Hide the menu at the start
	if pause_menu:
		pause_menu.visible = false
	
	# Use call_deferred to ensure the scene tree is fully loaded before running setup
	_setup_level.call_deferred()

func _setup_level() -> void:
	var level_placeholder = get_node_or_null("LevelPlaceholder") #
	
	if level_placeholder:
		var enemies = level_placeholder.get_node_or_null("Enemies") #
		
		# Connect to all existing enemies to listen for the player's death signal
		if enemies:
			for enemy in enemies.get_children():
				if enemy.has_signal("player_died"):
					# Ensure the enemy signal is connected to the local _on_player_died function
					enemy.player_died.connect(_on_player_died)

func _on_player_died(body: Node2D) -> void:
	# Check if the player is still alive before triggering the death sequence
	if body.has_method("die") and body.get("alive") == true:
		print("You Died.")
		body.die()

# --- PAUSE MENU LOGIC ---

func _on_pause_pressed() -> void:
	toggle_pause()

func toggle_pause() -> void:
	# Toggle the engine's pause state
	get_tree().paused = not get_tree().paused
	
	# Show/Hide the menu based on pause state
	if pause_menu:
		pause_menu.visible = get_tree().paused
	
	# Update the main pause button text/visibility
	if get_tree().paused:
		pause_button.text = "Resume"
	else:
		pause_button.text = "Pause"

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_restart_pressed() -> void:

	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	# Unpause and change to the main menu scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
