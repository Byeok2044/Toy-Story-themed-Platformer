extends CharacterBody2D

@export var player_id := 1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump sound"
@onready var death_sound: AudioStreamPlayer2D = $"death sound"
@onready var rope_line: Line2D = get_node_or_null("Line2D") 

const SPEED = 300.0
const JUMP_VELOCITY = -850.0
const LASSO_RANGE = 300.0 
const SWING_FORCE = 800.0
const GRAVITY_MULTIPLIER = 1.5

var alive = true 
var health = 5
var hearts_list : Array = [] 

var is_lasso_active := false
var lasso_target_pos := Vector2.ZERO

func _ready() -> void:
	if rope_line:
		rope_line.visible = false
	var hearts_parent = get_node_or_null("Health Bar/HBoxContainer")
	if hearts_parent:
		for child in hearts_parent.get_children():
			hearts_list.append(child)
		health = hearts_list.size()

func take_damage():
	if not alive: return
	
	health -= 1
	print("Ouch! Health is now: ", health)

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(10.0)
	if hearts_list.size() > 0:
		var heart = hearts_list.pop_back()
		heart.queue_free()
	if health <= 0:
		die() 
	else:
		play_hurt_animation()

func play_hurt_animation():
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)

func _input(event: InputEvent) -> void:
	if not alive: return
	
	if event.is_action_pressed("lasso"):
		try_lasso()

func try_lasso():
	var hooks = get_tree().get_nodes_in_group("hooks")
	var closest_hook = null
	var min_dist = LASSO_RANGE

	for hook in hooks:
		var dist = global_position.distance_to(hook.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_hook = hook

	if closest_hook:
		lasso_target_pos = closest_hook.global_position
		is_lasso_active = true

func _physics_process(delta: float) -> void:
	if not alive: return

	var jump := "p%d_jump" % player_id
	var left := "p%d_left" % player_id
	var right := "p%d_right" % player_id

	if is_lasso_active:
		var radius_vec = global_position - lasso_target_pos
		var current_dist = radius_vec.length()
		velocity.y += get_gravity().y * delta * GRAVITY_MULTIPLIER
		var input_dir = Input.get_axis(left, right)
		velocity.x += input_dir * SPEED * delta * 2.0
		if current_dist > 50: 
			var angle_dir = radius_vec.normalized()
			if velocity.dot(angle_dir) > 0:
				velocity -= angle_dir * velocity.dot(angle_dir)
		if Input.is_action_just_pressed(jump):
			is_lasso_active = false
			velocity.y = JUMP_VELOCITY 
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
			animated_sprite_2d.animation = "jump"
		
		if is_on_floor() and Input.is_action_just_pressed(jump):
			velocity.y = JUMP_VELOCITY
			jump_sound.play()

		var direction := Input.get_axis(left, right)
		if direction != 0:
			velocity.x = direction * SPEED
			animated_sprite_2d.animation = "run"
			animated_sprite_2d.flip_h = (direction == -1)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor():
				animated_sprite_2d.animation = "idle"

	move_and_slide()

func _process(_delta: float) -> void:
	if rope_line:
		if is_lasso_active:
			rope_line.visible = true
			rope_line.clear_points()
			rope_line.add_point(Vector2.ZERO) 
			rope_line.add_point(to_local(lasso_target_pos))
		else:
			rope_line.visible = false

func die() -> void:
	if not alive: return
	alive = false
	is_lasso_active = false 
	death_sound.play()
	animated_sprite_2d.play("hit")
	set_collision_layer_value(1, false) 
	await get_tree().create_timer(2.0).timeout 
	get_tree().reload_current_scene()
