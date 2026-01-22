extends CharacterBody2D

@export var player_id := 2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump sound"
@onready var death_sound: AudioStreamPlayer2D = $"death sound"
@onready var fuel_bar: ProgressBar = $"Health Bar/FuelBar"

@onready var shoot_timer: Timer = $ShootTimer
@export var bullet_scene: PackedScene = preload("res://Scenes/Game Objects/buzz_bullet.tscn")
@export var shoot_cooldown := 0.4 
var can_shoot := true

const SPEED = 300.0
const JUMP_VELOCITY = -900.0
const FLOAT_FORCE = -400.0 
const MAX_FUEL = 0.9        
const FUEL_REGEN_RATE = 0.5

var alive = true 
var health = 5
var hearts_list : Array = [] 
var has_tank := false
var fuel := 0.0
var is_floating := false


var invulnerable = false 

func _ready() -> void:
	print("Spawning at: ", Global.respawn_point)
	add_to_group("players")
	print("Player spawned. Global.respawn_point is: ", Global.respawn_point)
	if Global.respawn_point != null:
		global_position = Global.respawn_point + Vector2(player_id * 20, 0)
		print("Teleported to checkpoint!")
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.global_position = global_position 
			cam.reset_smoothing() 
		start_invulnerability(1.5)
	if Global.players_swapped:
		player_id = 1
	else:
		player_id = 2
		
	var hearts_parent = get_node_or_null("Health Bar/HBoxContainer")
	if hearts_parent:
		for child in hearts_parent.get_children():
			hearts_list.append(child)
		health = hearts_list.size()
	if Global.respawn_point != null:
		global_position = Global.respawn_point
		start_invulnerability(1.5)

	fuel = MAX_FUEL
	if fuel_bar:
		fuel_bar.visible = false
		fuel_bar.max_value = MAX_FUEL
		
	if shoot_timer:
		shoot_timer.one_shot = true
		if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
			shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _input(event: InputEvent) -> void:
	if not alive: return
	
	var shoot_action := "p%d_shoot" % player_id
	if event.is_action_pressed(shoot_action) and can_shoot:
		shoot()

func shoot():
	if not bullet_scene: return
	
	can_shoot = false
	if shoot_timer:
		shoot_timer.start(shoot_cooldown)
	
	var bullet = bullet_scene.instantiate()
	var is_flipped = animated_sprite_2d.flip_h
	var jump_action := "p%d_jump" % player_id
	var down_action := "p%d_down" % player_id
	
	bullet.shooter = self
	
	var horiz_dir = -1.0 if is_flipped else 1.0
	var vert_dir = 0.0
	if Input.is_action_pressed(jump_action):
		vert_dir = -0.5
	elif Input.is_action_pressed(down_action):
		vert_dir = 0.5
		
	bullet.direction = Vector2(horiz_dir, vert_dir).normalized()
	bullet.rotation = bullet.direction.angle() 

	get_parent().add_child(bullet)
	var spawn_offset = Vector2(horiz_dir * 30, vert_dir * 10)
	bullet.global_position = global_position + spawn_offset

func _on_shoot_timer_timeout():
	can_shoot = true

func _physics_process(delta: float) -> void:
	if not alive: return
		
	var left := "p%d_left" % player_id
	var right := "p%d_right" % player_id
	var jump := "p%d_jump" % player_id

	if has_tank and Input.is_action_pressed(jump) and not is_on_floor() and fuel > 0:
		is_floating = true
		velocity.y = FLOAT_FORCE 
		fuel -= delta
		
		var current_alpha = animated_sprite_2d.modulate.a
		animated_sprite_2d.modulate = Color(0, 1, 1, current_alpha)
		
		if fuel <= 0:
			has_tank = false
			if fuel_bar: fuel_bar.visible = false
			animated_sprite_2d.modulate = Color.WHITE
			print("Tank empty! Lost the jetpack.")
	else:
		is_floating = false
		if not invulnerable: 
			animated_sprite_2d.modulate = Color.WHITE

	if not is_on_floor():
		if not is_floating:
			velocity += get_gravity() * delta
			animated_sprite_2d.animation = "jump"
	else:
		if has_tank:
			fuel = move_toward(fuel, MAX_FUEL, FUEL_REGEN_RATE * delta)

	if Input.is_action_just_pressed(jump) and is_on_floor():
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
	
	if fuel_bar:
		fuel_bar.value = fuel
		fuel_bar.visible = has_tank

func collect_tank():
	has_tank = true
	fuel = MAX_FUEL
	if fuel_bar:
		fuel_bar.visible = true 
	print("Buzz picked up the tank!")

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
	await tree.create_timer(2.0).timeout 
	
	if tree:
		tree.reload_current_scene()
