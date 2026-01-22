extends CharacterBody2D

@export var player_id := 1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump sound"
@onready var death_sound: AudioStreamPlayer2D = $"death sound"

const SPEED = 300.0
const JUMP_VELOCITY = -850.0

var alive = true 
var health = 5
var hearts_list : Array = [] 

var invulnerable = false 

func _ready() -> void:
	if Global.respawn_point != null:
		invulnerable = true 
		global_position = Global.respawn_point
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.global_position = global_position
			if cam.has_method("reset_smoothing"):
				cam.reset_smoothing() 
		start_invulnerability(2.0) 

	var hearts_parent = $"Health Bar/HBoxContainer"
	for child in hearts_parent.get_children():
		hearts_list.append(child)
	health = hearts_list.size()

func start_invulnerability(duration: float):
	invulnerable = true
	var tween = create_tween().set_loops(int(duration * 5))
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.5, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1)
	
	await get_tree().create_timer(duration).timeout
	invulnerable = false
	if animated_sprite_2d:
		animated_sprite_2d.modulate.a = 1.0

func take_damage():
	if not alive or invulnerable: return
	
	health -= 1
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(10.0) 
		
	if hearts_list.size() > 0:
		var heart = hearts_list.pop_back()
		heart.queue_free()
		
	if health <= 0:
		die() 
	else:
		play_hurt_animation()
		start_invulnerability(0.5) 

func play_hurt_animation():
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)

func _physics_process(delta: float) -> void:
	if not alive:
		return
		
	var left := "p%d_left" % player_id
	var right := "p%d_right" % player_id
	var jump := "p%d_jump" % player_id

	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jump"

	if Input.is_action_just_pressed(jump) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	var direction := Input.get_axis(left, right)

	if direction != 0:
		velocity.x = direction * SPEED
		animated_sprite_2d.animation = "run"
		animated_sprite_2d.flip_h = (direction == -1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			animated_sprite_2d.animation = "idle"

	move_and_slide()

func die() -> void:
	if not alive: return
	alive = false
	death_sound.play()
	animated_sprite_2d.play("hit")
	set_collision_layer_value(1, false) 
	
	var tree = get_tree() 
	await tree.create_timer(2.0).timeout 
	
	if tree: 
		tree.reload_current_scene()
