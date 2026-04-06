extends Area2D

@export var warning_time := 3.0
@export var active_time := 2.0
@export var damage_interval: float = 0.5 

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D 

enum State { IDLE, WARNING, ACTIVE }
var _current_state: State = State.IDLE
var _tween: Tween
var _damage_timer: float = 0.0 

func _ready() -> void:
	visible = true 
	_reset_to_safe()

func _process(delta: float) -> void:
	if _current_state == State.ACTIVE:
		_damage_timer += delta
		if _damage_timer >= damage_interval:
			_apply_continuous_damage()
			_damage_timer = 0.0

func _reset_to_safe() -> void:
	_current_state = State.IDLE
	_damage_timer = 0.0
	if _tween: _tween.kill()
	
	sprite.visible = false
	sprite.modulate = Color(1, 1, 1, 0)
	
	monitoring = false
	monitorable = false
	collision_shape_2d.set_deferred("disabled", true)

func trigger_sequence() -> void:
	if _current_state != State.IDLE:
		return
	_run_spike_cycle()

func is_sequence_active() -> bool:
	return _current_state != State.IDLE

func _run_spike_cycle() -> void:
	_current_state = State.WARNING
	
	sprite.visible = true
	sprite.modulate = Color(1, 0, 0, 0.5)
	
	_tween = create_tween().set_loops()
	_tween.tween_property(sprite, "modulate:a", 0.8, 0.1)
	_tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
	
	await get_tree().create_timer(warning_time).timeout
	if _current_state != State.WARNING: return

	_current_state = State.ACTIVE
	
	if _tween: _tween.kill()
	
	sprite.visible = true 
	sprite.modulate = Color(1, 1, 1, 1) 

	monitoring = true
	collision_shape_2d.set_deferred("disabled", false)

	_apply_continuous_damage()
	
	await get_tree().create_timer(active_time).timeout
	if _current_state != State.ACTIVE: return

	collision_shape_2d.set_deferred("disabled", true)
	monitoring = false
	
	await get_tree().physics_frame
	
	_reset_to_safe()

func _apply_continuous_damage() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("players") and body.has_method("take_damage"):
			body.take_damage()

func _on_body_entered(body: Node2D) -> void:
	if _current_state == State.ACTIVE:
		if body.is_in_group("players") and body.has_method("take_damage"):
			body.take_damage()
			_damage_timer = 0.0
