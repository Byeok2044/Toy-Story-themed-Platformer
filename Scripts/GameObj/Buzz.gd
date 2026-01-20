extends CharacterBody2D

@export var player_id := 2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump sound"
@onready var death_sound: AudioStreamPlayer2D = $"death sound"
@onready var fuel_bar: ProgressBar = $"Health Bar/FuelBar"
@export var bullet_scene: PackedScene = preload("res://Scenes/Game Objects/buzz_bullet.tscn")

const SPEED = 300.0
const JUMP_VELOCITY = -850.0
const FLOAT_FORCE = -400.0 
const MAX_FUEL = 0.9       
const FUEL_REGEN_RATE = 0.5

var alive = true 
var health = 5
var hearts_list : Array = [] 
var has_tank := false
var fuel := 0.0
var is_floating := false

func _ready() -> void:
	var hearts_parent = $"Health Bar/HBoxContainer"
	for child in hearts_parent.get_children():
		hearts_list.append(child)
	health = hearts_list.size()
	fuel = MAX_FUEL
	if fuel_bar:
		fuel_bar.visible = false
		fuel_bar.max_value = MAX_FUEL

func collect_tank():
	has_tank = true
	fuel = MAX_FUEL
	if fuel_bar:
		fuel_bar.visible = true 
	print("Buzz picked up the tank!")

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

func _physics_process(delta: float) -> void:
	if not alive:
		return
		
	var left := "p%d_left" % player_id
	var right := "p%d_right" % player_id
	var jump := "p%d_jump" % player_id
	var shoot_action := "p2_shoot" # Variable renamed for clarity

	# This must be at the same level as the variables above
	if Input.is_action_just_pressed(shoot_action):
		print("Attempting to shoot...") # Debug message
		shoot() 



	if has_tank and Input.is_action_pressed(jump) and not is_on_floor() and fuel > 0:
		is_floating = true
		velocity.y = FLOAT_FORCE 
		fuel -= delta
		animated_sprite_2d.modulate = Color.CYAN 
		
		if fuel <= 0:
			has_tank = false
			fuel_bar.visible = false
			animated_sprite_2d.modulate = Color.WHITE
			print("Tank empty! Lost the jetpack.")
	else:
		is_floating = false
		if not is_floating:
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

func die() -> void:
	if not alive: return
	alive = false
	death_sound.play()
	animated_sprite_2d.play("hit")
	set_collision_layer_value(1, false) 
	await get_tree().create_timer(2.0).timeout 
	get_tree().reload_current_scene()

func shoot():
	var bullet = bullet_scene.instantiate()
	var is_flipped = animated_sprite_2d.flip_h
	
	# 1. Set the shooter reference first
	bullet.shooter = self
	
	# 2. Determine Direction
	var horiz_dir = -1.0 if is_flipped else 1.0
	var vert_dir = 0.0
	if Input.is_action_pressed("p2_jump"):
		vert_dir = -0.5
	elif Input.is_action_pressed("p2_down"):
		vert_dir = 0.5
		
	bullet.direction = Vector2(horiz_dir, vert_dir).normalized()
	bullet.rotation = bullet.direction.angle() 

	# 3. ADD TO PARENT FIRST
	get_parent().add_child(bullet)
	
	# 4. SET GLOBAL POSITION AFTER ADDING TO TREE
	var spawn_offset = Vector2(horiz_dir * 60, vert_dir * 20)
	bullet.global_position = global_position + spawn_offset
