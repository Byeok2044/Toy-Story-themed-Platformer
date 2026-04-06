extends Node2D

@onready var boss: Area2D = $Boss
@onready var boss_ui: CanvasLayer = $BossUI
@onready var victory_ui: CanvasLayer = $Victory
@onready var boss_camera: Camera2D = $BossCamera
@onready var camera_target: Node2D = $CameraTarget
@onready var arena_barrier: CollisionShape2D = $ArenaBarrier/CollisionShape2D
@onready var boss_music: AudioStreamPlayer2D = $BossMusic

@onready var restart: Button = $Victory/Panel/Restart
@onready var main_menu: Button = $"Victory/Panel/Main Menu"

var previous_camera: Camera2D = null
var players: Array[Node2D] = []
var is_boss_defeated: bool = false

@export_group("Camera Settings")
@export var fixed_zoom: Vector2 = Vector2(0.4, 0.4)
@export var smoothing_speed: float = 5.0

func _ready() -> void:
	if not boss_camera or not camera_target:
		push_error("MISSING NODES: Check BossCamera and CameraTarget names.")
		return
	
	boss_ui.visible = false
	victory_ui.visible = false
	boss_camera.zoom = fixed_zoom
	boss_camera.position_smoothing_enabled = true
	boss_camera.position_smoothing_speed = smoothing_speed
	
	if arena_barrier:
		arena_barrier.disabled = true
		
	if boss:
		if boss.has_signal("boss_died"):
			boss.boss_died.connect(_on_boss_defeated)
		else:
			boss.tree_exited.connect(_on_boss_defeated)
			
	if restart:
		restart.pressed.connect(_on_restart_pressed)
	if main_menu:
		main_menu.pressed.connect(_on_main_menu_pressed)

func _on_body_entered(body: Node2D) -> void:
	if is_boss_defeated:
		return

	if body.is_in_group("players"):
		if not body in players:
			players.append(body)
		
		if boss_music and not boss_music.playing:
			boss_music.play()
			
		if players.size() >= 2:
			trap_players()
		
		boss_ui.visible = true
		
		var current = get_viewport().get_camera_2d()
		if current and current != boss_camera:
			previous_camera = current
		boss_camera.make_current()

func trap_players() -> void:
	if arena_barrier:
		arena_barrier.set_deferred("disabled", false)
		print("Players trapped! Arena barrier active.")
	if boss and boss.has_method("start_attack_cycle"):
		boss.start_attack_cycle()

func _on_boss_defeated() -> void:
	if is_boss_defeated: return
	
	is_boss_defeated = true
	print("Victory! Boss defeated.")
	
	victory_ui.visible = true
	boss_ui.visible = false
	
	if boss_music and boss_music.playing:
		boss_music.stop()
		
	if arena_barrier:
		arena_barrier.set_deferred("disabled", true)

func _on_restart_pressed() -> void:
	if Global.respawn_point != null:
		Global.respawn_point = null
	
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	if Global.respawn_point != null:
		Global.respawn_point = null
		
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		players.erase(body)
		if players.is_empty() and not is_boss_defeated:
			if boss_music and boss_music.playing:
				boss_music.stop()
				
			boss_ui.visible = false
			
			if arena_barrier:
				arena_barrier.set_deferred("disabled", true)
				
			if previous_camera and is_instance_valid(previous_camera):
				previous_camera.make_current()

func _process(_delta: float) -> void:
	if players.is_empty() or not boss_camera or not camera_target:
		return
	boss_camera.global_position = camera_target.global_position
