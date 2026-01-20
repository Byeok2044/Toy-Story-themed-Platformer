extends Camera2D

@export var player1: Node2D
@export var player2: Node2D

@export_group("Limits")
@export var use_limits := true
@export var limit_left_val := -5000
@export var limit_top_val := -10000
@export var limit_right_val := 40000
@export var limit_bottom_val := 10000

@export_group("Zoom Settings")
@export var min_zoom := 0.5
@export var max_zoom := 1.5
@export var zoom_speed := 2.0
@export var zoom_margin := 1.5 

@export_group("Movement Settings")
@export var smooth_speed := 5.0

@export var shake_intensity := 5.0
var current_shake := 0.0

func _ready() -> void:
	if use_limits:
		limit_left = limit_left_val
		limit_top = limit_top_val
		limit_right = limit_right_val
		limit_bottom = limit_bottom_val
		limit_smoothed = true 

func _process(delta: float) -> void:
	var target_pos: Vector2
	var target_zoom_val: float
	if is_instance_valid(player1) and is_instance_valid(player2):
		target_pos = (player1.global_position + player2.global_position) / 2
		
		var distance = player1.global_position.distance_to(player2.global_position)
		var screen_size = get_viewport_rect().size
		
		var zoom_x = screen_size.x / (distance + screen_size.x / zoom_margin)
		var zoom_y = screen_size.y / (distance + screen_size.y / zoom_margin)
		
		target_zoom_val = clamp(min(zoom_x, zoom_y), min_zoom, max_zoom)
		
	elif is_instance_valid(player1):
		target_pos = player1.global_position
		target_zoom_val = max_zoom
	elif is_instance_valid(player2):
		target_pos = player2.global_position
		target_zoom_val = max_zoom
	else:
		return
	global_position = global_position.lerp(target_pos, delta * smooth_speed)
	var target_zoom_vec = Vector2(target_zoom_val, target_zoom_val)
	zoom = zoom.lerp(target_zoom_vec, delta * zoom_speed)
	if current_shake > 0:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * current_shake
		current_shake = move_toward(current_shake, 0, delta * 10.0)
	else:
		offset = Vector2.ZERO

func apply_shake(intensity: float):
	current_shake = intensity
