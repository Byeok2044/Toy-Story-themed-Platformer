extends Area2D

# UI and Detection
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_detector: RayCast2D = get_node_or_null("RayCast2D")

# Damage Settings
@export var contact_damage_interval := 0.6
var damage_cooldowns := {}
var bodies_in_hitbox: Array[Node2D] = []

# Movement Constants
const SPEED = 100.0
const LEDGE_NUDGE = 15.0

# State Variables
var direction: float = -1.0
var health: int = 3
var is_locked_to_edge: bool = false

func _physics_process(delta: float) -> void:
	if not floor_detector:
		return

	# Handle Movement
	position.x += direction * SPEED * delta
	
	floor_detector.force_raycast_update()
	
	# Ledge Detection logic
	var ledge_detected = not floor_detector.is_colliding()
	
	if ledge_detected:
		if not is_locked_to_edge:
			_flip_enemy()
			is_locked_to_edge = true
	else:
		is_locked_to_edge = false

func _process(_delta: float) -> void:
	# Constantly check for bodies inside the hitbox to apply continuous damage
	deal_contact_damage()

func _flip_enemy() -> void:
	direction *= -1.0
	animated_sprite_2d.flip_h = (direction > 0)
	
	# Move the raycast to the leading edge
	floor_detector.position.x = abs(floor_detector.position.x) * direction
	
	# Small nudge to prevent getting stuck on the ledge
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
		# Clean up invalid or dead targets
		if not is_instance_valid(body):
			bodies_in_hitbox.erase(body)
			damage_cooldowns.erase(body)
			continue

		if not body.get("alive"):
			continue

		# Check if the cooldown interval has passed
		var next_time = damage_cooldowns.get(body, 0.0)
		if now < next_time:
			continue

		# Apply damage
		if body.has_method("take_damage"):
			body.take_damage()
			damage_cooldowns[body] = now + contact_damage_interval

# --- Signals (Ensure these are connected in the Godot Editor) ---

func _on_body_entered(body: Node2D) -> void:
	# Only track the specific player nodes
	if (body.name == "Buzz" or body.name == "Woody"):
		if not bodies_in_hitbox.has(body):
			bodies_in_hitbox.append(body)

func _on_body_exited(body: Node2D) -> void:
	# Stop tracking damage when the player leaves contact
	bodies_in_hitbox.erase(body)
	damage_cooldowns.erase(body)

func die() -> void:
	set_physics_process(false)
	queue_free()
