extends Area2D

@export var speed: float = 400.0
@export var steer_force: float = 500.0      
@export var lifetime: float = 3.0
@export var lead_strength: float = 0.6    

var velocity: Vector2
var target: Node2D

func start(spawn_transform: Transform2D, new_target: Node2D = null) -> void:
	global_transform = spawn_transform
	velocity = transform.x.normalized() * speed
	target = new_target
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		move_straight(delta)
		return

	var desired_velocity := get_desired_velocity()
	var steer := (desired_velocity - velocity)
	steer = steer.limit_length(steer_force)

	velocity = (velocity + steer * delta).normalized() * speed

	rotation = velocity.angle()
	position += velocity * delta

func get_desired_velocity() -> Vector2:
	var target_pos := target.global_position
	
	if target.get("velocity"):
		target_pos += target.velocity * lead_strength
	
	return (target_pos - global_position).normalized() * speed

func move_straight(delta: float) -> void:
	rotation = velocity.angle()
	position += velocity * delta
	
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage()
		queue_free()
		return
	if body is TileMap or body is TileMapLayer or body.is_in_group("walls") or body is StaticBody2D:
		queue_free()
