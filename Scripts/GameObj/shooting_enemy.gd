extends Area2D

@export var laser_scene: PackedScene = preload("res://Scenes/Game Objects/laser.tscn")
@export var shoot_direction: Vector2 = Vector2.LEFT 
@export var health: int = 3 
@export var speed: float = 100.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var wall_detector: RayCast2D = $RayCast2D

signal player_damaged

var direction: float = -1.0

func _process(delta: float) -> void:
	position.x += direction * speed * delta
	if wall_detector.is_colliding():
		flip_enemy()

func flip_enemy() -> void:
	direction *= -1
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
	muzzle.position.x *= -1
	shoot_direction = Vector2(direction, 0)
	wall_detector.target_position.x *= -1
	wall_detector.position.x *= -1

func _on_shot_timer_timeout() -> void:
	shoot()

func shoot() -> void:
	if laser_scene:
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
			if body.has_method("take_damage"):
				body.take_damage()
				player_damaged.emit()

func take_damage(amount: int) -> void:
	health -= amount
	
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()
	else:
		if animated_sprite_2d.sprite_frames.has_animation("hit"):
			animated_sprite_2d.play("hit")
			await get_tree().create_timer(0.2).timeout
			animated_sprite_2d.play("default")

func die() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	if animated_sprite_2d.sprite_frames.has_animation("hit"):
		animated_sprite_2d.play("hit")
		await animated_sprite_2d.animation_finished
	
	queue_free()
