extends Area2D

@export var homing_laser_scene: PackedScene
@export var health: int = 50
@export var shoot_interval: float = 2.0

@onready var muzzle: Marker2D = $Muzzle # Add a Marker2D node where bullets spawn
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_timer: Timer = $ShootTimer # Add a Timer node

# This flag controls the immunity
var immune_to_normal_bullets: bool = true

func _ready() -> void:
	# Start the shooting cycle
	shoot_timer.wait_time = shoot_interval
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	if homing_laser_scene:
		var laser = homing_laser_scene.instantiate()
		get_parent().add_child(laser)
		
		# Shoot to the left (or towards player) initially
		var shoot_dir = Vector2.LEFT 
		
		# If you have a muzzle, use its position, otherwise use boss position
		var spawn_pos = muzzle.global_position if muzzle else global_position
		
		if laser.has_method("start"):
			laser.start(spawn_pos, shoot_dir)

# This function is called by your 'buzz_bullet.gd'
func take_damage(amount: int) -> void:
	if immune_to_normal_bullets:
		# VISUAL FEEDBACK: Blink Blue to indicate "Shielded/Immune"
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.CYAN, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		return # EXIT HERE so health is not reduced
	
	# Normal damage logic (if you disable immunity later)
	health -= amount
	
	# Blink Red for actual damage
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func die() -> void:
	queue_free()
