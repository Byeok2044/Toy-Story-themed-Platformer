extends Node2D

func _ready() -> void:
	_setup_level.call_deferred()

func _setup_level() -> void:
	var level_placeholder = get_node_or_null("LevelPlaceholder")
	var enemies = level_placeholder.get_node_or_null("Enemies")
	
	if enemies:
		for enemy in enemies.get_children():
			if enemy.has_signal("player_died"):
				enemy.player_died.connect(_on_player_died)

func _on_player_died(body: Node2D) -> void:
	if body.has_method("die") and body.get("alive") == true:
		print("You Died.")
		body.die()
