extends Area2D

var direction = Vector2.ZERO
var speed = 1000.0
var hooked = false
var parent_player = null

func _physics_process(delta):
	if hooked:
		return 
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("hookable") or body is StaticBody2D:
		hooked = true
