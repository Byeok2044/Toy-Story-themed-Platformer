extends Area2D

@export var speed: float = 500.0
@export var max_distance: float = 500.0 

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null 
var traveled_distance: float = 0.0

func _process(delta: float) -> void:
	var movement = direction * speed * delta
	position += movement
	traveled_distance += movement.length()
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if (body.name == "Buzz" or body.name == "Woody") and body.get("alive"):
		if body.has_method("take_damage"):
			body.take_damage() 
			queue_free()
	else:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
