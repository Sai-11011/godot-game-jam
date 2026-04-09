extends Area2D

var speed: float = 800.0

func _ready():
	# 1. Start tiny and slightly transparent
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.5
	
	# 2. BURST OUTWARD (The Swing)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)
	
	# 3. DISSIPATE (Stretch forward and fade away as it flies)
	var die_tween = create_tween().set_parallel(true)
	die_tween.tween_property(self, "scale:x", 2.0, 0.3).set_delay(0.1) 
	die_tween.tween_property(self, "scale:y", 0.1, 0.3).set_delay(0.1) 
	die_tween.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.15)

func _physics_process(delta: float):
	var forward_direction = Vector2.RIGHT.rotated(rotation)
	global_position += forward_direction * speed * delta

func _on_timer_timeout():
	queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(PlayerData.current_damage)
			var push_direction = Vector2.RIGHT.rotated(rotation)
			var force = PlayerData.knockback_forces["slash"]
			body.receive_knockback(push_direction * force)

func _on_area_entered(area: Area2D):
	if area.is_in_group("Enemy"):
		if area.has_method("take_damage"):
			area.take_damage(PlayerData.current_damage)
			var push_direction = Vector2.RIGHT.rotated(rotation)
			var force = PlayerData.knockback_forces["slash"]
			area.receive_knockback(push_direction * force)
