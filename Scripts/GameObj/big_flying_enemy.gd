extends CharacterBody2D

# NEW: Add a custom signal so the boss knows when this specific object "dies"
signal destroyed 

const speed = 120.0 
const ACCEL = 8.0 
const RETURN_SPEED = 100.0

@export var health: int = 10
@export var max_health: int = 10 # Added for resetting health each cycle
@export var max_distance: float = 600.0 
@export var detection_radius: float = 350.0 
@export var flip_cooldown: float = 0.25 
@export var contact_damage_interval := 0.6

var damage_cooldowns := {} 
var dir: Vector2
var is_bat_chase: bool = false
var target: CharacterBody2D = null 
var alive: bool = true
var home_position: Vector2
var last_flip_time: float = 0.0 
var bodies_in_hitbox: Array[Node2D] = [] 

# NEW: Track if the enemy has been activated by the boss
var _active: bool = false 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready():
	home_position = global_position
	# Essential for the Boss script to track its destruction
	add_to_group("enemies") 
	# NEW: Start hidden and dormant
	_reset_to_hidden()

# NEW: Logic to stay hidden and non-functional at start
func _reset_to_hidden() -> void:
	_active = false
	alive = false # Disable logic processing
	visible = false
	set_physics_process(false)
	set_process(false)
	# Disable collisions so it doesn't block players or take damage while hidden
	$CollisionShape2D.set_deferred("disabled", true)

# NEW: Function called by the Boss to start the enemy
func trigger_sequence() -> void:
	if _active: return
	_active = true
	alive = true
	health = max_health # Reset health for the new phase
	
	visible = true
	set_physics_process(true)
	set_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Reset position to home marker to prevent drifting between cycles
	global_position = home_position
	
	if timer:
		timer.start()

func _process(_delta):
	# SAFETY: Double check active state
	if not alive or not _active: return 
	update_target_logic()
	handle_animation()

func update_target_logic():
	var dist_from_home = global_position.distance_to(home_position)
	
	if dist_from_home > max_distance:
		is_bat_chase = false
		target = null
		return

	var nearest = find_nearest_player()
	
	if nearest is CharacterBody2D:
		var diff = nearest.global_position - global_position
		var weighted_dist = Vector2(diff.x, diff.y * 0.7).length()
		
		if weighted_dist <= detection_radius:
			is_bat_chase = true
			target = nearest
		elif not is_bat_chase:
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
	# SAFETY: Double check active state
	if not alive or not _active: return 
	deal_contact_damage()
	
	var target_velocity = Vector2.ZERO
	var dist_from_home = global_position.distance_to(home_position)
	
	if target and is_bat_chase:
		var p_vel = target.velocity if "velocity" in target else Vector2.ZERO
		var target_pos = target.global_position + (p_vel * 0.1)
		target_velocity = global_position.direction_to(target_pos) * speed
	elif dist_from_home > 20.0:
		target_velocity = global_position.direction_to(home_position) * RETURN_SPEED
	else:
		target_velocity = dir * (speed * 0.5)
		
	velocity = velocity.lerp(target_velocity, ACCEL * delta)
	move_and_slide()

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
			velocity = global_position.direction_to(body.global_position) * -200

func handle_animation():
	if not alive: return
	if animated_sprite_2d.sprite_frames.has_animation("fly"):
		animated_sprite_2d.play("fly")
	
	if abs(velocity.x) > 5.0:
		var current_time = Time.get_ticks_msec() / 1000.0
		var wants_to_flip = (velocity.x < 0) != animated_sprite_2d.flip_h
		
		if wants_to_flip and (current_time - last_flip_time) >= flip_cooldown:
			animated_sprite_2d.flip_h = (velocity.x < 0)
			last_flip_time = current_time

func take_damage(amount: int = 1):
	# Cannot take damage if the boss hasn't activated it yet
	if not alive or not _active: return 
	health -= amount
	
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func die():
	# NEW: Instead of deleting (queue_free), hide it and tell the boss it's "destroyed"
	_reset_to_hidden()
	destroyed.emit()

func _on_timer_timeout() -> void:
	if not _active: return
	timer.wait_time = randf_range(0.8, 2.0)
	if not is_bat_chase:
		dir = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.ZERO].pick_random()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not _active: return
	if body.is_in_group("players") and not bodies_in_hitbox.has(body):
		bodies_in_hitbox.append(body)
		damage_cooldowns[body] = 0.0

func _on_hitbox_body_exited(body: Node2D) -> void:
	bodies_in_hitbox.erase(body)
