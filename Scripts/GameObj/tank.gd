extends Area2D

@onready var sprite = $Sprite2D 
@onready var collision = $CollisionShape2D

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_tank"):
		body.collect_tank()
		respawn_logic()

func respawn_logic():
	visible = false
	collision.set_deferred("disabled", true)
	await get_tree().create_timer(10.0).timeout
	visible = true
	collision.set_deferred("disabled", false)
