extends Area2D


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_detector: RayCast2D = get_node_or_null("RayCast2D")
@export var contact_damage_interval := 0.6
var damage_cooldowns := {}
var bodies_in_hitbox: Array[Node2D] = []


const SPEED = 100.0
const LEDGE_NUDGE = 15.0


var direction: float = -1.0
var health: int = 3
var is_locked_to_edge: bool = false

func _physics_process(delta: float) -> void:
	if not floor_detector:
		return


	position.x += direction * SPEED * delta
	
	floor_detector.force_raycast_update()
	

	var ledge_detected = not floor_detector.is_colliding()
	
	if ledge_detected:
		if not is_locked_to_edge:
			_flip_enemy()
			is_locked_to_edge = true
	else:
		is_locked_to_edge = false

func _process(_delta: float) -> void:
	deal_contact_damage()

func _flip_enemy() -> void:
	direction *= -1.0
	animated_sprite_2d.flip_h = (direction > 0)
	
	floor_detector.position.x = abs(floor_detector.position.x) * direction
	
	position.x += direction * LEDGE_NUDGE
	
	floor_detector.force_raycast_update()

func take_damage(amount: int) -> void:
	health -= amount
	var flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		die()

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
			damage_cooldowns[body] = now + contact_damage_interval


func _on_body_entered(body: Node2D) -> void:
	if (body.name == "Buzz" or body.name == "Woody"):
		if not bodies_in_hitbox.has(body):
			bodies_in_hitbox.append(body)

func _on_body_exited(body: Node2D) -> void:
	bodies_in_hitbox.erase(body)
	damage_cooldowns.erase(body)

func die() -> void:
	set_physics_process(false)
	queue_free()
