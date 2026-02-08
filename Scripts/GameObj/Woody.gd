extends CharacterBody2D

@export var player_id := 1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump sound"
@onready var death_sound: AudioStreamPlayer2D = $"death sound"
@onready var hit_sound: AudioStreamPlayer2D = $"hit sound"

@onready var rope_line: Line2D = get_node_or_null("Line2D") 
@onready var melee_area: Area2D = $MeleeArea
@onready var melee_timer: Timer = $MeleeTimer

var is_attacking := false

const SPEED = 300.0
const JUMP_VELOCITY = -900.0
const LASSO_RANGE = 400.0 
const GRAVITY_MULTIPLIER = 1.5

var alive = true 
var health = 5
var hearts_list : Array = [] 
var is_lasso_active := false
var lasso_target_pos := Vector2.ZERO
var invulnerable = false 

func _ready() -> void:
	add_to_group("players")
	
	player_id = 2 if Global.players_swapped else 1
	
	if Global.respawn_point != null:
		global_position = Global.respawn_point + Vector2(player_id * 20, 0)
		
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.global_position = global_position
			if cam.has_method("reset_smoothing"):
				cam.reset_smoothing()
		
		start_invulnerability(1.5)
	
	if rope_line:
		rope_line.visible = false
		
	if melee_area:
		melee_area.monitoring = false
		if not melee_area.body_entered.is_connected(_on_melee_hit):
			melee_area.body_entered.connect(_on_melee_hit)
		if not melee_area.area_entered.is_connected(_on_melee_hit):
			melee_area.area_entered.connect(_on_melee_hit)

	var hearts_parent = get_node_or_null("Health Bar/HBoxContainer")
	if hearts_parent:
		hearts_list.clear() 
		for child in hearts_parent.get_children():
			hearts_list.append(child)
		health = hearts_list.size()

func _input(event: InputEvent) -> void:
	if not alive: return
	
	var lasso_action := "p%d_lasso" % player_id
	var melee_action := "p%d_melee" % player_id
	
	if event.is_action_pressed(lasso_action):
		try_lasso()
		
	if event.is_action_pressed(melee_action) and not is_attacking:
		perform_melee()

func perform_melee():
	is_attacking = true
	
	if animated_sprite_2d.sprite_frames.has_animation("attack"):
		animated_sprite_2d.play("attack")
	
	if melee_area:
		melee_area.monitoring = true
		melee_area.position.x = -40 if animated_sprite_2d.flip_h else 40
	
	if melee_timer:
		melee_timer.start()
		await melee_timer.timeout
	else:
		await get_tree().create_timer(0.3).timeout
	
	if melee_area:
		melee_area.monitoring = false
	
	is_attacking = false

func _on_melee_hit(target_node):
	if target_node.is_in_group("enemies") and target_node.has_method("take_damage"):
		target_node.take_damage(1)

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

	var jump_action := "p%d_jump" % player_id
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
				
		if Input.is_action_just_pressed(jump_action):
			is_lasso_active = false
			velocity.y = JUMP_VELOCITY 
	else:
		# APPLY GRAVITY
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# JUMP LOGIC
		if is_on_floor() and Input.is_action_just_pressed(jump_action):
			velocity.y = JUMP_VELOCITY
			jump_sound.play()
			get_tree().create_timer(0.5).timeout.connect(func(): if jump_sound: jump_sound.stop())

		# HORIZONTAL MOVEMENT
		var direction := Input.get_axis(left, right)
		if direction != 0:
			velocity.x = direction * SPEED
			animated_sprite_2d.flip_h = (direction == -1)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# ANIMATION STATE MACHINE
		if not is_attacking:
			if not is_on_floor():
				animated_sprite_2d.play("jump")
			elif direction != 0:
				animated_sprite_2d.play("run")
			else:
				animated_sprite_2d.play("idle")

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

func start_invulnerability(duration: float):
	invulnerable = true
	var tween = create_tween().set_loops(int(duration * 5))
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.5, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1)
	
	await get_tree().create_timer(duration).timeout
	invulnerable = false
	if animated_sprite_2d:
		animated_sprite_2d.modulate.a = 1.0

func take_damage():
	if not alive or invulnerable: return
	
	if hit_sound:
		hit_sound.play()
	
	health -= 1
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(0.5) 
	if hearts_list.size() > 0:
		var heart = hearts_list.pop_back()
		if is_instance_valid(heart):
			heart.queue_free()
	if health <= 0:
		die()
	else:
		play_hurt_animation()
		start_invulnerability(0.5)

func play_hurt_animation():
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if not alive: return
	alive = false
	death_sound.play()
	animated_sprite_2d.play("hit")
	set_collision_layer_value(1, false)
	
	var tree = get_tree()
	await tree.create_timer(2.4).timeout
	
	if tree:
		tree.reload_current_scene()
