extends CharacterBody2D

const speed = 80.0
const RETURN_SPEED = 100.0
@export var health: int = 3
@export var max_distance: float = 400.0 
@export var flip_cooldown: float = 0.5 
@export var contact_damage_interval := 0.6
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
	
	var dist_from_home = global_position.distance_to(home_position)
	
	if dist_from_home > max_distance:
		is_bat_chase = false 
		target = null
	
	if is_bat_chase and dist_from_home <= max_distance:
		target = find_nearest_player()
	else:
		target = null
	
	handle_animation()

func _physics_process(delta):
	if not alive: return
	deal_contact_damage()
	move(delta)

func deal_contact_damage():
	var now := Time.get_ticks_msec() / 1000.0

	for body in bodies_in_hitbox.duplicate():
		if not is_instance_valid(body):
			bodies_in_hitbox.erase(body)
			damage_cooldowns.erase(body)
			continue

		if not body.is_in_group("players") or not body.get("alive"):
			continue

		var next_time = damage_cooldowns.get(body, 0.0)
		if now < next_time:
			continue

		if body.has_method("take_damage"):
			body.take_damage()
			damage_cooldowns[body] = now + contact_damage_interval


			velocity = global_position.direction_to(body.global_position) * -100

func find_nearest_player():
	var players = get_tree().get_nodes_in_group("players")
	var nearest_player = null
	var min_dist = INF
	
	for p in players:
		var dist = global_position.distance_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_player = p
			
	return nearest_player

func move(_delta):
	var dist_from_home = global_position.distance_to(home_position)
	
	if target and is_bat_chase:
		velocity = global_position.direction_to(target.global_position) * speed
	elif dist_from_home > 50.0: 
		velocity = global_position.direction_to(home_position) * RETURN_SPEED
	else:
		velocity = dir * speed
		
	move_and_slide()

func handle_animation():
	if not alive: return
	
	animated_sprite_2d.play("fly")
	
	if abs(velocity.x) > 2.0:
		var current_time = Time.get_ticks_msec() / 1000.0
		var wants_to_flip = (velocity.x < 0) != animated_sprite_2d.flip_h
		
		if wants_to_flip and (current_time - last_flip_time) >= flip_cooldown:
			animated_sprite_2d.flip_h = (velocity.x < 0)
			last_flip_time = current_time

func take_damage(amount: int = 1):
	if not alive: return
	health -= amount
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func die():
	if not alive: return
	alive = false
	velocity = Vector2.ZERO
	bodies_in_hitbox.clear()
	collision_layer = 0
	collision_mask = 0
	
	if animated_sprite_2d.sprite_frames.has_animation("die"):
		animated_sprite_2d.play("die")
		await animated_sprite_2d.animation_finished
	
	queue_free()

func _on_timer_timeout() -> void:
	timer.wait_time = randf_range(1.5, 3.5)
	if !is_bat_chase:
		dir = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.ZERO].pick_random()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		is_bat_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		is_bat_chase = false
		target = null

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not alive: return
	if body.is_in_group("players"):
		if not bodies_in_hitbox.has(body):
			bodies_in_hitbox.append(body)
		damage_cooldowns[body] = 0.0 

func _on_hitbox_body_exited(body: Node2D) -> void:
	bodies_in_hitbox.erase(body)
	damage_cooldowns.erase(body)
