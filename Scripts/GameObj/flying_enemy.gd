extends CharacterBody2D

# Constants and Variables
const speed = 50.0
@export var health: int = 3
@export var player_id := 2 # Useful if you need to identify players

var dir: Vector2
var is_bat_chase: bool = false
var target: CharacterBody2D = null
var alive: bool = true

# Node References
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready():
	# Automatically add to enemies group so the laser can hit it
	add_to_group("enemies")
	timer.start()

func _process(delta):
	if not alive: return
	
	# Find the nearest player every frame if in chase mode
	if is_bat_chase:
		target = find_nearest_player()
	
	move(delta)
	handle_animation()

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

func move(delta):
	if is_bat_chase and target: 
		# Use global_position for more accurate direction tracking
		velocity = global_position.direction_to(target.global_position) * speed
	elif !is_bat_chase:
		# Wander movement
		velocity = dir * speed
		
	move_and_slide()

func handle_animation():
	if not alive: return
	
	animated_sprite_2d.play("fly")
	
	# Flip sprite based on movement direction
	if velocity.x < 0:
		animated_sprite_2d.flip_h = true
	elif velocity.x > 0:
		animated_sprite_2d.flip_h = false

func take_damage(amount: int):
	if not alive: return
	
	health -= amount
	print("Bat hit! Health remaining: ", health)
	
	# Visual feedback (Flashing Red)
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func die():
	if not alive: return
	alive = false
	
	# Stop movement and collisions
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Play hit/death animation if it exists
	if animated_sprite_2d.sprite_frames.has_animation("die"):
		animated_sprite_2d.play("die")
		await animated_sprite_2d.animation_finished
	
	queue_free()

func _on_timer_timeout() -> void:
	timer.wait_time = choose([1.0, 1.5, 2.0])
	if !is_bat_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN])

func choose(array):
	array.shuffle()
	return array.front()

# --- Signal Connections ---

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		is_bat_chase = true
		print("Bat started chasing: ", body.name)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		is_bat_chase = false
		dir = choose([Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN])

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage()
		# Knockback effect on the bat when it hits a player
		velocity = global_position.direction_to(body.global_position) * -200
