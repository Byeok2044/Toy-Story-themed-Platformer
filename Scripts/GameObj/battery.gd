extends Area2D

# 1. Add a custom signal so the boss knows when this specific object "dies"
signal destroyed 

@export var max_health: int = 15
@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_health: int
var _active: bool = false

func _ready() -> void:
	add_to_group("enemies")
	_reset_to_hidden()

func _reset_to_hidden() -> void:
	_active = false
	visible = false
	collision_shape.set_deferred("disabled", true) # Cannot be hit
	if health_bar: health_bar.visible = false

# Boss calls this to "Spawn" the battery (Reuse it)
func trigger_sequence() -> void:
	_active = true
	current_health = max_health # Reset Health
	
	# Show and Enable
	visible = true
	sprite.modulate = Color(1, 1, 1, 1)
	collision_shape.set_deferred("disabled", false)
	
	if health_bar:
		health_bar.visible = true
		health_bar.max_value = max_health
		health_bar.value = current_health

func take_damage(amount: int) -> void:
	if not _active: return 
	
	current_health -= amount
	if health_bar: health_bar.value = current_health
	
	# Flash Effect
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_health <= 0:
		die()

func die() -> void:
	# Instead of deleting (queue_free), we just hide it and tell the boss
	_reset_to_hidden()
	destroyed.emit() # Notify boss
