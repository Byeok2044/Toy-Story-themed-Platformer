extends CharacterBody2D

const speed = 120.0 
const ACCEL = 8.0 
const RETURN_SPEED = 100.0

@export var health: int = 3
@export var max_distance: float = 600.0 
@export var detection_radius: float = 350.0 
@export var flip_cooldown: float = 0.25 

# --- UPDATED COOLDOWN HERE (2.0 Seconds) ---
@export var contact_damage_interval := 2.0

var damage_cooldowns := {} 
var dir: Vector2
var is_bat_chase: bool = false
var target: CharacterBody2D = null 
var alive: bool = true
var home_position: Vector2
var last_flip_time: float = 0.0 
var bodies_in_hitbox: Array[Node2D] = [] 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready():
	home_position = global_position
	add_to_group("enemies") 
	timer.start()

func _process(_delta):
	if not alive: return
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
	if not alive: return
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
			# Update the cooldown map with the current time + 2 seconds
			damage_cooldowns[body] = now + contact_damage_interval
			# Knockback effect
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
	if not alive: return
	health -= amount
	
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color(10, 10, 10, 1), 0.08)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.08)
	
	if health <= 0:
		die()

func die():
	if not alive: return
	alive = false
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false) 
	
	if animated_sprite_2d.sprite_frames.has_animation("die"):
		animated_sprite_2d.play("die")
		await animated_sprite_2d.animation_finished
	
	queue_free()

func _on_timer_timeout() -> void:
	timer.wait_time = randf_range(0.8, 2.0)
	if not is_bat_chase:
		dir = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.ZERO].pick_random()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and not bodies_in_hitbox.has(body):
		bodies_in_hitbox.append(body)
		# Initialize with 0 so they can be hit immediately upon first contact
		if not damage_cooldowns.has(body):
			damage_cooldowns[body] = 0.0 

func _on_hitbox_body_exited(body: Node2D) -> void:
	bodies_in_hitbox.erase(body)
