extends CharacterBody2D

@export var player_id := 2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump sound"
@onready var death_sound: AudioStreamPlayer2D = $"death sound"
@onready var fuel_bar: ProgressBar = $"Health Bar/FuelBar"

# --- Cooldown & Combat Variables ---
@onready var shoot_timer: Timer = $ShootTimer # Ensure your scene has a Timer child node named "ShootTimer"
@export var bullet_scene: PackedScene = preload("res://Scenes/Game Objects/buzz_bullet.tscn")
@export var shoot_cooldown := 0.4 # Seconds between shots
var can_shoot := true

# --- Constants ---
const SPEED = 300.0
const JUMP_VELOCITY = -850.0
const FLOAT_FORCE = -400.0 
const MAX_FUEL = 0.9        
const FUEL_REGEN_RATE = 0.5

# --- State Variables ---
var alive = true 
var health = 5
var hearts_list : Array = [] 
var has_tank := false
var fuel := 0.0
var is_floating := false

func _ready() -> void:
	# DYNAMIC CONTROL SWAP:
	# By default, Buzz is P2 (Arrows). If swapped, he becomes P1 (WASD).
	if Global.players_swapped:
		player_id = 1
	else:
		player_id = 2
		
	# Setup health UI
	var hearts_parent = get_node_or_null("Health Bar/HBoxContainer")
	if hearts_parent:
		for child in hearts_parent.get_children():
			hearts_list.append(child)
		health = hearts_list.size()
		
	# Setup fuel system
	fuel = MAX_FUEL
	if fuel_bar:
		fuel_bar.visible = false
		fuel_bar.max_value = MAX_FUEL
		
	# Setup Shoot Timer logic
	if shoot_timer:
		shoot_timer.one_shot = true
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _input(event: InputEvent) -> void:
	if not alive: return
	
	# Dynamically determine the shoot action based on current player_id
	# (p2_shoot = Right Shift | p1_shoot = E)
	var shoot_action := "p%d_shoot" % player_id
	if event.is_action_pressed(shoot_action) and can_shoot:
		shoot()

func shoot():
	if not bullet_scene: return
	
	# Start Cooldown
	can_shoot = false
	if shoot_timer:
		shoot_timer.start(shoot_cooldown)
	
	# Instantiate and configure the bullet
	var bullet = bullet_scene.instantiate()
	var is_flipped = animated_sprite_2d.flip_h
	var jump_action := "p%d_jump" % player_id
	var down_action := "p%d_down" % player_id
	
	bullet.shooter = self
	
	# Determine shooting direction dynamically based on facing and aim keys
	var horiz_dir = -1.0 if is_flipped else 1.0
	var vert_dir = 0.0
	if Input.is_action_pressed(jump_action):
		vert_dir = -0.5
	elif Input.is_action_pressed(down_action):
		vert_dir = 0.5
		
	bullet.direction = Vector2(horiz_dir, vert_dir).normalized()
	bullet.rotation = bullet.direction.angle() 

	# Add to scene and position correctly
	get_parent().add_child(bullet)
	var spawn_offset = Vector2(horiz_dir * 30, vert_dir * 10)
	bullet.global_position = global_position + spawn_offset

func _on_shoot_timer_timeout():
	can_shoot = true

func _physics_process(delta: float) -> void:
	if not alive: return
		
	# Fetch dynamic actions for movement
	var left := "p%d_left" % player_id
	var right := "p%d_right" % player_id
	var jump := "p%d_jump" % player_id

	# Jetpack / Float logic
	if has_tank and Input.is_action_pressed(jump) and not is_on_floor() and fuel > 0:
		is_floating = true
		velocity.y = FLOAT_FORCE 
		fuel -= delta
		animated_sprite_2d.modulate = Color.CYAN 
		
		if fuel <= 0:
			has_tank = false
			if fuel_bar: fuel_bar.visible = false
			animated_sprite_2d.modulate = Color.WHITE
			print("Tank empty! Lost the jetpack.")
	else:
		is_floating = false
		animated_sprite_2d.modulate = Color.WHITE

	# Handle Vertical Gravity/Jumping
	if not is_on_floor():
		if not is_floating:
			velocity += get_gravity() * delta
			animated_sprite_2d.animation = "jump"
	else:
		if has_tank:
			fuel = move_toward(fuel, MAX_FUEL, FUEL_REGEN_RATE * delta)

	# Jump trigger logic
	if Input.is_action_just_pressed(jump) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()
		
	# Horizontal Movement
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
	
	# Update UI elements
	if fuel_bar:
		fuel_bar.value = fuel
		fuel_bar.visible = has_tank

func collect_tank():
	has_tank = true
	fuel = MAX_FUEL
	if fuel_bar:
		fuel_bar.visible = true 
	print("Buzz picked up the tank!")

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
	death_sound.play()
	animated_sprite_2d.play("hit")
	set_collision_layer_value(1, false) 
	
	await get_tree().create_timer(2.0).timeout 
	get_tree().reload_current_scene()
