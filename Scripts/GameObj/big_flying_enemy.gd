extends CharacterBody2D

signal destroyed 

@export_group("Movement")
const SPEED = 140.0 
const ACCEL = 5.0      # Lower = weightier, Higher = snappier
const FRICTION = 4.0   # How fast it slows down
const RETURN_SPEED = 100.0
const STEERING_FORCE = 0.1 # How sharply it can turn while chasing

@export_group("Combat")
@export var health: int = 10
@export var max_health: int = 10
@export var contact_damage_interval := 2.0

@export_group("Detection")
@export var max_distance: float = 600.0 
@export var detection_radius: float = 350.0 
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

func _ready():
	home_position = global_position
	add_to_group("enemies") 
	_reset_to_hidden()

func _reset_to_hidden() -> void:
	_active = false
	alive = false
	visible = false
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
	update_target_logic()
	handle_animation()

func update_target_logic():
	var dist_from_home = global_position.distance_to(home_position)
	
	# If too far from home, force a return
	if dist_from_home > max_distance:
		is_bat_chase = false
		target = null
		return

	var nearest = find_nearest_player()
	
	if nearest is CharacterBody2D:
		var dist = global_position.distance_to(nearest.global_position)
		
		# HYSTERESIS: Use a larger radius to stop chasing than to start it
		# This prevents "flickering" logic at the edge of the circle
		var effective_radius = detection_radius * (1.2 if is_bat_chase else 1.0)
		
		if dist <= effective_radius:
			is_bat_chase = true
			target = nearest
		else:
			is_bat_chase = false
			target = null
	else:
		is_bat_chase = false
		target = null

func find_nearest_player() -> CharacterBody2D:
	var players = get_tree().get_nodes_in_group("players")
	var nearest_player: CharacterBody2D = null
	var min_dist = INF
	
	for p in players:
		if p is CharacterBody2D and p.get("alive") != false:
			var dist = global_position.distance_to(p.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_player = p
	return nearest_player

func _physics_process(delta):
	if not alive or not _active: return 
	deal_contact_damage()
	
	var desired_velocity = Vector2.ZERO
	var dist_from_home = global_position.distance_to(home_position)
	
	if target and is_bat_chase:
		# SMOOTH CHASE: Predict target position slightly and steer toward it
		var p_vel = target.velocity if "velocity" in target else Vector2.ZERO
		var target_pos = target.global_position + (p_vel * 0.1)
		var target_dir = global_position.direction_to(target_pos)
		
		# Blend current velocity direction with target direction for a "curve" effect
		desired_velocity = target_dir * SPEED
		velocity = velocity.lerp(desired_velocity, STEERING_FORCE) 
		
	elif dist_from_home > 30.0:
		# SMOOTH RETURN
		desired_velocity = global_position.direction_to(home_position) * RETURN_SPEED
		velocity = velocity.lerp(desired_velocity, ACCEL * delta)
	else:
		# IDLE WANDER / FRICTION
		if dir != Vector2.ZERO:
			desired_velocity = dir * (SPEED * 0.4)
			velocity = velocity.lerp(desired_velocity, ACCEL * delta)
		else:
			velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)
		
	move_and_slide()

# ... (rest of your functions: deal_contact_damage, handle_animation, take_damage, die, etc.)

func handle_animation():
	if not alive: return
	if animated_sprite_2d.sprite_frames.has_animation("fly"):
		animated_sprite_2d.play("fly")
	
	# Only flip if moving horizontally with enough intent
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
			# Knockback
			velocity = global_position.direction_to(body.global_position) * -250
