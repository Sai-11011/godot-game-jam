extends Area2D

var speed: float = 600.0

func _physics_process(delta: float):
	var forward_direction = Vector2.RIGHT.rotated(rotation)
	global_position += forward_direction * speed * delta

func _on_timer_timeout():
	queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(PlayerData.current_damage)
			
			# Grab the exact forward direction of the slash
			var push_direction = Vector2.RIGHT.rotated(rotation)
			var force = PlayerData.knockback_forces["slash"]
			body.receive_knockback(push_direction * force)
