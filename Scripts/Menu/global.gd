extends Node2D

var playerBody: CharacterBody2D
var respawn_point = null
var players_swapped: bool = false
var dead_enemies: Array = []

@onready var pause_menu = %PauseMenu
@onready var pause_button: Button = $HUD/Pause
@onready var victory_menu = %VictoryMenu 

@onready var general: AudioStreamPlayer2D = $General
@onready var combat: AudioStreamPlayer2D = $Combat

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_menu:
		pause_menu.visible = false
	if victory_menu:
		victory_menu.visible = false
	
	play_music("general")
	_setup_level.call_deferred()

func _setup_level() -> void:
	var level_placeholder = get_node_or_null("LevelPlaceholder")
	if level_placeholder:
		var enemies = level_placeholder.get_node_or_null("Enemies")
		if enemies:
			for enemy in enemies.get_children():
				if enemy.has_signal("player_died"):
					if not enemy.player_died.is_connected(_on_player_died):
						enemy.player_died.connect(_on_player_died)
		var boss_node = level_placeholder.find_child("Boss", true, false)
		if boss_node and boss_node.has_signal("boss_defeated"):
			boss_node.boss_defeated.connect(_on_game_finished)

func _on_game_finished() -> void:
	print("Boss Defeated! Game Finished.")
	get_tree().paused = true 
	play_music("stop_all")
	if victory_menu:
		victory_menu.visible = true
	if pause_button:
		pause_button.visible = false

func play_music(mode: String) -> void:
	if general == null or combat == null:
		return

	match mode:
		"general":
			if not general.playing:
				general.play()
				combat.stop()
		"combat":
			if not combat.playing:
				combat.play()
				general.stop()
		"stop_all":
			general.stop()
			combat.stop()

func _on_player_died(body: Node2D) -> void:
	if is_instance_valid(body) and body.has_method("die") and body.get("alive") == true:
		print("You Died.")
		play_music("stop_all")
		body.die()

func _on_pause_pressed() -> void:
	toggle_pause()

func toggle_pause() -> void:
	if victory_menu and victory_menu.visible:
		return
		
	get_tree().paused = not get_tree().paused
	if pause_menu:
		pause_menu.visible = get_tree().paused
	if pause_button:
		pause_button.visible = not get_tree().paused

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_restart_pressed() -> void:
	if Global.get("respawn_point") != null:
		Global.respawn_point = null
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
