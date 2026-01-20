extends Area2D

@export var speed: float = 600.0
var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null 

func _process(delta: float) -> void:
	position += direction * speed * delta

# Connect this signal in the Godot Editor
func _on_area_entered(area: Area2D) -> void:
	if area == shooter: return
	
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(1)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == shooter or body.is_in_group("players"):
		return

	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
	elif body is TileMapLayer or body is TileMap:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
