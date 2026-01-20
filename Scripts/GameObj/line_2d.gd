extends Line2D

@export var player: Node2D
@export var hook: Node2D

func _process(_delta: float) -> void:
	if hook and player:
		clear_points()
		add_point(player.global_position)
		add_point(hook.global_position)
		visible = true
	else:
		visible = false
