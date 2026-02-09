extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		var spawn_node = get_node_or_null("RespawnPoint")
		
		if spawn_node:
			Global.respawn_point = spawn_node.global_position
		else:
			Global.respawn_point = global_position
