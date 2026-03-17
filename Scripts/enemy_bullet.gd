extends Area2D

var damage: int = 10 # Default value; the shooter will update this when spawning the bullet
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0

func _physics_process(delta: float) -> void:
	# Move smoothly regardless of framerate
	global_position += direction * speed * delta 

func _on_body_entered(body: Node2D) -> void:
	# Safely check for the player and apply damage
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		print("a")
		# Don't forget to delete the bullet after it hits!
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
