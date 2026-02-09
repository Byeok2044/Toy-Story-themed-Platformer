extends Area2D

@export var speed: float = 500.0
@export var max_distance: float = 600.0 

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null 
var traveled_distance: float = 0.0

func start(pos: Vector2, dir: Vector2) -> void:
	global_position = pos
	direction = dir.normalized()
	rotation = direction.angle()

func _process(delta: float) -> void:
	var movement = direction * speed * delta
	position += movement
	
	traveled_distance += movement.length()
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == shooter or body.is_in_group("enemies"):
		return
	
	if body.is_in_group("players"):
		if body.get("alive") == true:
			if body.has_method("take_damage"):
				body.take_damage()
				queue_free()
	else:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
