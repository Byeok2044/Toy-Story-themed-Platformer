extends Area2D

@export var warning_time := 3.0
@export var active_time := 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D

enum State { IDLE, WARNING, ACTIVE }
var _current_state: State = State.IDLE
var _tween: Tween

func _ready() -> void:
	# Ensure the Area2D itself is visible and processing
	visible = true 
	_reset_to_safe()

func _reset_to_safe() -> void:
	_current_state = State.IDLE
	if _tween: _tween.kill()
	
	# Visual Reset
	sprite.visible = false
	sprite.modulate = Color(1, 1, 1, 0) # Clear transparency
	
	# Physics Reset
	monitoring = false
	monitorable = false
	collision_polygon_2d.set_deferred("disabled", true)

func trigger_sequence() -> void:
	if _current_state != State.IDLE:
		return
	_run_spike_cycle()

func is_sequence_active() -> bool:
	return _current_state != State.IDLE

func _run_spike_cycle() -> void:
	# =================================================
	# 1. WARNING PHASE
	# =================================================
	_current_state = State.WARNING
	
	sprite.visible = true # FORCE VISIBILITY
	sprite.modulate = Color(1, 0, 0, 0.5) # Semi-transparent Red
	
	# Simple flicker
	_tween = create_tween().set_loops()
	_tween.tween_property(sprite, "modulate:a", 0.8, 0.1)
	_tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
	
	await get_tree().create_timer(warning_time).timeout
	if _current_state != State.WARNING: return

	# =================================================
	# 2. ACTIVE PHASE
	# =================================================
	_current_state = State.ACTIVE
	
	if _tween: _tween.kill()
	
	# Ensure solid white and visible
	sprite.visible = true 
	sprite.modulate = Color(1, 1, 1, 1) 
	
	# Enable Collision
	monitoring = true
	collision_polygon_2d.set_deferred("disabled", false)
	
	await get_tree().create_timer(active_time).timeout
	if _current_state != State.ACTIVE: return

	# =================================================
	# 3. RESET PHASE
	# =================================================
	# Disable collision BEFORE hiding sprite to prevent invisible damage
	collision_polygon_2d.set_deferred("disabled", true)
	monitoring = false
	
	# Wait for physics to sync
	await get_tree().physics_frame
	
	_reset_to_safe()

func _on_body_entered(body: Node2D) -> void:
	# Damage only if state is active and sprite is visible
	if _current_state == State.ACTIVE and sprite.visible:
		if body.is_in_group("players") and body.has_method("take_damage"):
			body.take_damage()
