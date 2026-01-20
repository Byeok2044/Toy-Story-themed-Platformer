extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		# Try to find a specific child node named "RespawnPoint"
		var spawn_node = get_node_or_null("RespawnPoint")
		
		if spawn_node:
			# If the node exists, use its position (allows for precise placement)
			Global.respawn_point = spawn_node.global_position
			print("Checkpoint saved at specific RespawnPoint: ", Global.respawn_point)
		else:
			# FALLBACK: If no child node exists, just use the Checkpoint's own center
			Global.respawn_point = global_position
			print("Checkpoint saved at Area2D location: ", Global.respawn_point)
