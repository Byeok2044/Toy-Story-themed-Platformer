extends Area2D

@export var warning_time := 3.0
@export var active_time := 2.0

@onready var sprite: Sprite2D = $Sprite2D
# --- CHANGED TO CollisionShape2D ---
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D 

enum State { IDLE, WARNING, ACTIVE }
var _current_state: State = State.IDLE
var _tween: Tween

func _ready() -> void:
	visible = true 
	_reset_to_safe()

func _reset_to_safe() -> void:
	_current_state = State.IDLE
	if _tween: _tween.kill()
	
	sprite.visible = false
	sprite.modulate = Color(1, 1, 1, 0)
	
	monitoring = false
	monitorable = false
	# Fix: Use the new variable name
	collision_shape_2d.set_deferred("disabled", true)

func trigger_sequence() -> void:
	if _current_state != State.IDLE:
		return
	_run_spike_cycle()

func is_sequence_active() -> bool:
	return _current_state != State.IDLE

func _run_spike_cycle() -> void:
	# 1. WARNING PHASE
	_current_state = State.WARNING
	
	sprite.visible = true
	sprite.modulate = Color(1, 0, 0, 0.5)
	
	_tween = create_tween().set_loops()
	_tween.tween_property(sprite, "modulate:a", 0.8, 0.1)
	_tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
	
	await get_tree().create_timer(warning_time).timeout
	if _current_state != State.WARNING: return

	# 2. ACTIVE PHASE
	_current_state = State.ACTIVE
	
	if _tween: _tween.kill()
	
	sprite.visible = true 
	sprite.modulate = Color(1, 1, 1, 1) 
	
	# Enable Collision
	monitoring = true
	# Fix: Changed from collision_polygon_2d to collision_shape_2d
	collision_shape_2d.set_deferred("disabled", false)
	
	await get_tree().create_timer(active_time).timeout
	if _current_state != State.ACTIVE: return

	# 3. RESET PHASE
	# Fix: Changed from collision_polygon_2d to collision_shape_2d
	collision_shape_2d.set_deferred("disabled", true)
	monitoring = false
	
	await get_tree().physics_frame
	
	_reset_to_safe()

func _on_body_entered(body: Node2D) -> void:
	if _current_state == State.ACTIVE and sprite.visible:
		if body.is_in_group("players") and body.has_method("take_damage"):
			body.take_damage()
