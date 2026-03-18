extends Area2D

var target_pos: Vector2
var explosion_radius: float = 100.0 # How wide the spread damage is
var damage: float = PlayerData.current_damage
var speed: float = 500.0
var pulse_tween: Tween 

func _ready():
	scale = Vector2(0.1, 0.1) #small to big
	
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	
	var tween = create_tween()
	tween.tween_interval(0.3) 
	
	var travel_time = global_position.distance_to(target_pos) / speed
	
	tween.tween_property(self, "global_position", target_pos, travel_time).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(explode)

func _on_body_entered(body: Node2D):
	if body.is_in_group("Enemy"):
		explode()

func explode():
	if pulse_tween:
		pulse_tween.kill()
	set_deferred("monitoring", false)
	var tween = create_tween()
	tween.set_parallel(true)
	# Use TRANS_QUART or TRANS_EXPO for that snappy "explosion" feel
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)

	# Scale up fast, then slow down
	tween.tween_property(self, "scale", Vector2(20.0, 20.0), 0.3)

	# Fade out (using EASE_IN makes it disappear more toward the end of the scale)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false) 
	tween.tween_callback(queue_free)
	
	# SPREAD DAMAGE & KNOCKBACK MATH
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= explosion_radius:
			
			if enemy.has_method("take_damage"):
				if PlayerData.heavy_is_active :
					enemy.take_damage(damage*5)
				else:
					enemy.take_damage(damage)
				PlayerData.apply_knockback(enemy, global_position, "bullet")
