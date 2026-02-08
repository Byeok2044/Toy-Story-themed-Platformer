extends Area2D

# Exported Variables
@export var laser_scene: PackedScene = preload("res://Scenes/Game Objects/laser.tscn")
@export var shoot_direction: Vector2 = Vector2.LEFT 
@export var health: int = 3 
@export var speed: float = 100.0

# Contact Damage Settings
@export var contact_damage_interval := 0.6
var damage_cooldowns := {}
var bodies_in_hitbox: Array[Node2D] = []

# Node References
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ledge_detector: RayCast2D = $LedgeDetector 

# --- NEW AUDIO REFERENCE ---
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound


signal player_damaged

var direction: float = -1.0

func _ready() -> void:
	if wall_detector:
		var players = get_tree().get_nodes_in_group("players")
		for player in players:
			if player is CollisionObject2D:
				wall_detector.add_exception(player)
	else:
		print("Warning: WallDetector node not found. Check your scene tree names.")

func _process(delta: float) -> void:
	position.x += direction * speed * delta
	if wall_detector.is_colliding() or not ledge_detector.is_colliding():
		flip_enemy()
	deal_contact_damage()

func deal_contact_damage():
	var now := Time.get_ticks_msec() / 1000.0

	for body in bodies_in_hitbox.duplicate():
		if not is_instance_valid(body):
			bodies_in_hitbox.erase(body)
			damage_cooldowns.erase(body)
			continue

		if not body.get("alive"):
			continue

		var next_time = damage_cooldowns.get(body, 0.0)
		if now < next_time:
			continue

		if body.has_method("take_damage"):
			body.take_damage()
			player_damaged.emit()
			damage_cooldowns[body] = now + contact_damage_interval

func flip_enemy() -> void:
	direction *= -1
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
	muzzle.position.x *= -1
	shoot_direction = Vector2(direction, 0)
	wall_detector.target_position.x *= -1
	wall_detector.position.x *= -1
	ledge_detector.position.x *= -1

func _on_shot_timer_timeout() -> void:
	shoot()

func shoot() -> void:
	if laser_scene:
		# --- TRIGGER SHOOT ANIMATION ---
		if animated_sprite_2d.sprite_frames.has_animation("shoot"):
			animated_sprite_2d.play("shoot")
			# Return to default after the shot is done
			get_tree().create_timer(0.4).timeout.connect(func(): 
				if animated_sprite_2d.animation == "shoot":
					animated_sprite_2d.play("default")
			)
		
		# Play the spatialized shoot sound
		if shoot_sound:
			shoot_sound.pitch_scale = randf_range(0.9, 1.1)
			shoot_sound.play()
			
		var laser = laser_scene.instantiate()
		get_parent().add_child(laser)
		laser.global_position = muzzle.global_position
		laser.direction = shoot_direction
		laser.rotation = shoot_direction.angle()
		laser.shooter = self

func _on_body_entered(body: Node2D) -> void:
	if (body.name == "Buzz" or body.name == "Woody") and body.get("alive"):
		if body.velocity.y > 10: 
			body.velocity.y = -500 
			take_damage(1)
		else:
			if not bodies_in_hitbox.has(body):
				bodies_in_hitbox.append(body)
				damage_cooldowns[body] = 0.0

func _on_body_exited(body: Node2D) -> void:
	bodies_in_hitbox.erase(body)
	damage_cooldowns.erase(body)

func take_damage(amount: int) -> void:
	health -= amount
	
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()
	else:
		# Hit feedback while still alive
		if animated_sprite_2d.sprite_frames.has_animation("hit"):
			animated_sprite_2d.play("hit")
			await get_tree().create_timer(0.2).timeout
			animated_sprite_2d.play("default")

func die() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	queue_free()
