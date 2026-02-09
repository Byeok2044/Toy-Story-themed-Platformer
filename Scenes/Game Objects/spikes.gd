extends Area2D

@export var damage_amount: int = 10
@export var damage_interval: float = 0.5 

@onready var sprite: Sprite2D = $Sprite2D

var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer += delta
	
	if _timer >= damage_interval:
		_apply_continuous_damage()
		_timer = 0.0 

func _apply_continuous_damage() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if body.is_in_group("players") and body.has_method("take_damage"):
			body.take_damage()
