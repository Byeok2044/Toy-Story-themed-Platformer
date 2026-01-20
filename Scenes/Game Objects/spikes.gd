extends Node2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage()
		print("Player hit the spikes!")
