extends Area2D

var speed: float = 800.0

func _physics_process(delta: float):
	var forward_direction = Vector2.RIGHT.rotated(rotation)
	global_position += forward_direction * speed * delta

func _on_timer_timeout():
	queue_free()

# This hits standard enemies and CharacterBody2D nodes
func _on_body_entered(body: Node2D):
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(PlayerData.current_damage)
			
			var push_direction = Vector2.RIGHT.rotated(rotation)
			var force = PlayerData.knockback_forces["slash"]
			body.receive_knockback(push_direction * force)

# This hits Area2D nodes
func _on_area_entered(area: Area2D):
	if area.is_in_group("Enemy"):
		if area.has_method("take_damage"):
			area.take_damage(PlayerData.current_damage)
			
			var push_direction = Vector2.RIGHT.rotated(rotation)
			var force = PlayerData.knockback_forces["slash"]
			area.receive_knockback(push_direction * force)
