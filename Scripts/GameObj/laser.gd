extends Area2D

@export var speed: float = 500.0
@export var max_distance: float = 600.0 

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null 
var traveled_distance: float = 0.0

# Function to initialize the laser's position and direction
func start(pos: Vector2, dir: Vector2) -> void:
	global_position = pos
	direction = dir.normalized()
	rotation = direction.angle()

func _process(delta: float) -> void:
	# Standard straight-line movement
	var movement = direction * speed * delta
	position += movement
	
	# Cleanup based on distance to prevent memory leaks
	traveled_distance += movement.length()
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Ignore the enemy who shot the laser
	if body == shooter or body.is_in_group("enemies"):
		return
	
	# Target Woody or Buzz specifically
	if body.is_in_group("players"):
		# Safely check if the player is alive before dealing damage
		if body.get("alive") == true:
			if body.has_method("take_damage"):
				body.take_damage()
				queue_free()
	else:
		# Destroy the laser if it hits walls or other objects
		queue_free()

# Optional: Cleanup if the laser leaves the screen
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
