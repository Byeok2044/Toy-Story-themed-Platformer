extends CharacterBody2D

signal destroyed 

@export_group("Movement")
const SPEED = 140.0 
const ACCEL = 5.0      
const FRICTION = 4.0   
const RETURN_SPEED = 100.0
const STEERING_FORCE = 0.1 

@export_group("Combat")
@export var health: int = 5
@export var max_health: int = 5
@export var contact_damage_interval := 2.0

@export_group("Detection")
@export var max_distance: float = 600.0 
@export var flip_cooldown: float = 0.25 

var damage_cooldowns := {} 
var dir: Vector2
var is_bat_chase: bool = false
var target: CharacterBody2D = null 
var alive: bool = true
var home_position: Vector2
var last_flip_time: float = 0.0 
var bodies_in_hitbox: Array[Node2D] = [] 
var _active: bool = false 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var detection_area: Area2D = $DetectionArea

func _ready():
	home_position = global_position
	add_to_group("enemies") 
	
	if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	if not detection_area.body_exited.is_connected(_on_detection_area_body_exited):
		detection_area.body_exited.connect(_on_detection_area_body_exited)
		
	_reset_to_hidden()

func _reset_to_hidden() -> void:
	_active = false
	alive = false
	visible = false
	is_bat_chase = false
	target = null
	set_physics_process(false)
	set_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

func trigger_sequence() -> void:
	if _active: return
	_active = true
	alive = true
	health = max_health
	visible = true
	set_physics_process(true)
	set_process(true)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", false)
	global_position = home_position
	if timer:
		timer.start()

func _process(_delta):
	if not alive or not _active: return 
	handle_animation()

func _physics_process(delta):
	if not alive or not _active: return 
	deal_contact_damage()
	
	var desired_velocity = Vector2.ZERO
	var dist_from_home = global_position.distance_to(home_position)
	
	if dist_from_home > max_distance:
		is_bat_chase = false
		target = null

	if target and is_bat_chase:
		var p_vel = target.velocity if "velocity" in target else Vector2.ZERO
		var target_pos = target.global_position + (p_vel * 0.1)
		var target_dir = global_position.direction_to(target_pos)
		
		desired_velocity = target_dir * SPEED
		velocity = velocity.lerp(desired_velocity, STEERING_FORCE) 
		
	elif dist_from_home > 30.0:
		desired_velocity = global_position.direction_to(home_position) * RETURN_SPEED
		velocity = velocity.lerp(desired_velocity, ACCEL * delta)
	else:
		if dir != Vector2.ZERO:
			desired_velocity = dir * (SPEED * 0.4)
			velocity = velocity.lerp(desired_velocity, ACCEL * delta)
		else:
			velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)
		
	move_and_slide()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.get("alive") != false:
		target = body as CharacterBody2D
		is_bat_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		is_bat_chase = false

func deal_contact_damage():
	var now := Time.get_ticks_msec() / 1000.0
	for body in bodies_in_hitbox.duplicate():
		if not is_instance_valid(body) or body.get("alive") == false:
			bodies_in_hitbox.erase(body)
			continue

		var next_time = damage_cooldowns.get(body, 0.0)
		if now < next_time: continue

		if body.has_method("take_damage"):
			body.take_damage()
			damage_cooldowns[body] = now + contact_damage_interval
			velocity = global_position.direction_to(body.global_position) * -250

func handle_animation():
	if not alive: return
	if animated_sprite_2d.sprite_frames.has_animation("fly"):
		animated_sprite_2d.play("fly")
	
	if abs(velocity.x) > 10.0:
		var current_time = Time.get_ticks_msec() / 1000.0
		var wants_to_flip = (velocity.x < 0) != animated_sprite_2d.flip_h
		
		if wants_to_flip and (current_time - last_flip_time) >= flip_cooldown:
			animated_sprite_2d.flip_h = (velocity.x < 0)
			last_flip_time = current_time

func take_damage(amount: int = 1):
	if not alive or not _active: return 
	health -= amount
	
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color(10, 10, 10, 1), 0.08)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.08)
	
	if health <= 0:
		die()

func die():
	_reset_to_hidden()
	destroyed.emit()

func _on_timer_timeout() -> void:
	if not _active: return
	timer.wait_time = randf_range(1.0, 3.0)
	if not is_bat_chase:
		dir = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.ZERO].pick_random()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not _active: return
	if body.is_in_group("players") and not bodies_in_hitbox.has(body):
		bodies_in_hitbox.append(body)
		if not damage_cooldowns.has(body):
			damage_cooldowns[body] = 0.0

func _on_hitbox_body_exited(body: Node2D) -> void:
	bodies_in_hitbox.erase(body)
