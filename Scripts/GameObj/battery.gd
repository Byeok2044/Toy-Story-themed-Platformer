extends Area2D

signal destroyed 

@export var max_health: int = 15
@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite_damaged: Sprite2D = $Sprite2D2

var current_health: int
var _active: bool = false

func _ready() -> void:
	add_to_group("enemies")
	_reset_to_hidden()

func _reset_to_hidden() -> void:
	_active = false
	visible = false
	collision_shape.set_deferred("disabled", true) 
	if health_bar: health_bar.visible = false

func trigger_sequence() -> void:
	_active = true
	current_health = max_health 
	
	
	visible = true
	sprite.visible = true
	if sprite_damaged: 
		sprite_damaged.visible = false 
		sprite_damaged.modulate = Color.WHITE 
	
	sprite.modulate = Color.WHITE
	collision_shape.set_deferred("disabled", false)
	
	if health_bar:
		health_bar.visible = true
		health_bar.max_value = max_health
		health_bar.value = current_health

func take_damage(amount: int) -> void:
	if not _active: return 
	
	current_health -= amount
	if health_bar: health_bar.value = current_health
	
	if sprite_damaged and current_health <= (max_health / 2.0):
		sprite.visible = false
		sprite_damaged.visible = true
	
	var active_sprite = sprite_damaged if (sprite_damaged and sprite_damaged.visible) else sprite
	var tween = create_tween()
	tween.tween_property(active_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(active_sprite, "modulate", Color.WHITE, 0.1)
	
	if current_health <= 0:
		die()

func die() -> void:
	_reset_to_hidden()
	destroyed.emit() 
