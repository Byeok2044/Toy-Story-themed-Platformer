extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

signal player_damaged 

const SPEED = 100.0
var direction = -1.0
var health = 3 # Added health

func _process(delta: float) -> void:
	position.x += direction * SPEED * delta

func _on_timer_timeout() -> void:
	direction *= -1
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h

# This function is called by Buzz's laser
func take_damage(amount: int):
	health -= amount
	print("Enemy hit! Health remaining: ", health)
	
	# Visual feedback for taking damage
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func _on_body_entered(body: Node2D) -> void:
	if (body.name == "Buzz" or body.name == "Woody") and body.get("alive"):
		# Keep player collision logic if you still want enemies to hurt players
		if body.has_method("take_damage"):
			body.take_damage()
			player_damaged.emit()

func die():
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if animated_sprite_2d.sprite_frames.has_animation("hit"):
		animated_sprite_2d.play("hit")
		await animated_sprite_2d.animation_finished
	
	queue_free()
