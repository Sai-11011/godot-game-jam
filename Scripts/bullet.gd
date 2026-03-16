extends Area2D

var target_pos: Vector2
var explosion_radius: float = 100.0 # How wide the spread damage is
var damage: float = 50
var speed: float = 700.0

func _ready():
	scale = Vector2(0.3, 0.3) #small to big
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE)
	var tween = create_tween()
	tween.tween_interval(0.5) 
	
	# CALCULATE TRAVEL TIME (Distance divided by Speed)
	var travel_time = global_position.distance_to(target_pos) / speed
	
	tween.tween_property(self, "global_position", target_pos, travel_time).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(explode)

func _on_body_entered(body: Node2D):
	if body.is_in_group("Enemy"):
		explode()

func explode():
	set_deferred("monitoring", false)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(3.0, 3.0), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
	
	# SPREAD DAMAGE & KNOCKBACK MATH
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= explosion_radius:
			
			# Check for the correct function name!
			if enemy.has_method("take_damage"):
				if PlayerData.heavy_is_active :
					enemy.take_damage(damage*5)
				else:
					enemy.take_damage(damage)
				# Apply your global knockback
				PlayerData.apply_knockback(enemy, global_position, "bullet")
