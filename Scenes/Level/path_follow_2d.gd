extends PathFollow2D



func _ready() -> void:
	pass 



func _process(delta: float) -> void:
	progress_ratio += delta * 0.25
