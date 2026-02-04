extends Node2D

@onready var boss: Area2D = $Boss
@onready var boss_ui: CanvasLayer = $BossUI
@onready var boss_camera: Camera2D = $BossCamera
@onready var camera_target: Node2D = $CameraTarget

# FIXED: Pointing to the CollisionShape2D child where the 'disabled' property exists
@onready var arena_barrier: CollisionShape2D = $ArenaBarrier/CollisionShape2D

var previous_camera: Camera2D = null
var players: Array[Node2D] = []

@export_group("Camera Settings")
@export var fixed_zoom: Vector2 = Vector2(0.4, 0.4) 
@export var smoothing_speed: float = 5.0

func _ready() -> void:
	if not boss_camera or not camera_target:
		push_error("MISSING NODES: Check BossCamera and CameraTarget names.")
		return
	
	boss_ui.visible = false
	boss_camera.zoom = fixed_zoom
	boss_camera.position_smoothing_enabled = true
	boss_camera.position_smoothing_speed = smoothing_speed
	
	# Ensure the barrier is open at the start
	if arena_barrier:
		arena_barrier.disabled = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if not body in players:
			players.append(body)
		
		# If you have 2 players, wait until both are inside to trap them
		if players.size() >= 2:
			trap_players()
		
		boss_ui.visible = true
		
		# Camera Management
		var current = get_viewport().get_camera_2d()
		if current and current != boss_camera:
			previous_camera = current
		boss_camera.make_current()

# Function to enable the physical collision barrier and trigger the boss
func trap_players() -> void:
	if arena_barrier:
		# Use set_deferred to safely change physics properties during a collision callback
		arena_barrier.set_deferred("disabled", false)
		print("Players trapped! Arena barrier active.")
	
	# MOVED: Activate the boss only when players are trapped
	if boss and boss.has_method("start_attack_cycle"):
		boss.start_attack_cycle()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		players.erase(body)
		if players.is_empty():
			boss_ui.visible = false
			# Re-open the barrier if everyone leaves or dies
			if arena_barrier:
				arena_barrier.set_deferred("disabled", true)
			if previous_camera and is_instance_valid(previous_camera):
				previous_camera.make_current()

func _process(_delta: float) -> void:
	# Keep the camera centered on the arena target while players are inside
	if players.is_empty() or not boss_camera or not camera_target:
		return
	boss_camera.global_position = camera_target.global_position
