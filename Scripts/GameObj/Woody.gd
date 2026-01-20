extends CharacterBody2D

@export var player_id := 1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump sound"
@onready var death_sound: AudioStreamPlayer2D = $"death sound"
@onready var rope_line: Line2D = get_node_or_null("Line2D") 

# --- Melee Variables ---
@onready var melee_area: Area2D = $MeleeArea
@onready var melee_timer: Timer = $MeleeTimer
var is_attacking := false

# --- Constants ---
const SPEED = 300.0
const JUMP_VELOCITY = -850.0
const LASSO_RANGE = 400.0 
const GRAVITY_MULTIPLIER = 1.5

# --- State Variables ---
var alive = true 
var health = 5
var hearts_list : Array = [] 
var is_lasso_active := false
var lasso_target_pos := Vector2.ZERO

func _ready() -> void:
	# Set ID: P1 (WASD) or P2 (Arrows) based on Global swap setting
	player_id = 2 if Global.players_swapped else 1
	
	if rope_line:
		rope_line.visible = false
		
	# Setup Melee Detection
	if melee_area:
		melee_area.monitoring = false
		melee_area.body_entered.connect(_on_melee_hit)
		melee_area.area_entered.connect(_on_melee_hit)

	# Initialize health bar UI
	var hearts_parent = get_node_or_null("Health Bar/HBoxContainer")
	if hearts_parent:
		for child in hearts_parent.get_children():
			hearts_list.append(child)
		health = hearts_list.size()

func _input(event: InputEvent) -> void:
	if not alive: return
	
	# Dynamically construct action names based on player_id
	var lasso_action := "p%d_lasso" % player_id
	var melee_action := "p%d_melee" % player_id
	
	if event.is_action_pressed(lasso_action):
		try_lasso()
		
	if event.is_action_pressed(melee_action) and not is_attacking:
		perform_melee()

func perform_melee():
	is_attacking = true
	melee_area.monitoring = true
	
	# Visual Punch Effect using Tween
	var tween = create_tween()
	var original_scale = animated_sprite_2d.scale
	var punch_scale = Vector2(original_scale.x * 1.4, original_scale.y * 0.8)
	tween.tween_property(animated_sprite_2d, "scale", punch_scale, 0.1)
	tween.tween_property(animated_sprite_2d, "scale", original_scale, 0.1)
	
	# Position the hit area based on Woody's flip status
	melee_area.position.x = -40 if animated_sprite_2d.flip_h else 40
	
	melee_timer.start()
	await melee_timer.timeout
	
	melee_area.monitoring = false
	is_attacking = false

func _on_melee_hit(target_node):
	# Hits both Ground (Area2D) and Flying (CharacterBody2D) enemies
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

	# Fetch dynamic actions
	var jump := "p%d_jump" % player_id
	var left := "p%d_left" % player_id
	var right := "p%d_right" % player_id

	if is_lasso_active:
		# Lasso Swinging Physics
		var radius_vec = global_position - lasso_target_pos
		var current_dist = radius_vec.length()
		velocity.y += get_gravity().y * delta * GRAVITY_MULTIPLIER
		var input_dir = Input.get_axis(left, right)
		velocity.x += input_dir * SPEED * delta * 2.0
		
		# Constraint logic to keep Woody at a distance
		if current_dist > 50: 
			var angle_dir = radius_vec.normalized()
			if velocity.dot(angle_dir) > 0:
				velocity -= angle_dir * velocity.dot(angle_dir)
				
		# Release lasso with Jump action
		if Input.is_action_just_pressed(jump):
			is_lasso_active = false
			velocity.y = JUMP_VELOCITY 
	else:
		# Standard Movement
		if not is_on_floor():
			velocity += get_gravity() * delta
			if not is_attacking:
				animated_sprite_2d.animation = "jump"
		
		if is_on_floor() and Input.is_action_just_pressed(jump):
			velocity.y = JUMP_VELOCITY
			jump_sound.play()

		var direction := Input.get_axis(left, right)
		if direction != 0:
			velocity.x = direction * SPEED
			if not is_attacking:
				animated_sprite_2d.animation = "run"
				animated_sprite_2d.flip_h = (direction == -1)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor() and not is_attacking:
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

func take_damage():
	if not alive: return
	health -= 1
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

func die() -> void:
	if not alive: return
	alive = false
	is_lasso_active = false 
	death_sound.play()
	animated_sprite_2d.play("hit")
	set_collision_layer_value(1, false) 
	await get_tree().create_timer(2.0).timeout 
	get_tree().reload_current_scene()
